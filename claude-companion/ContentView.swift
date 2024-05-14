import SwiftUI

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
}

extension Color {
    static let systemGray6 = Color(.sRGB, red: 0.6, green: 0.6, blue: 0.6, opacity: 1)
}

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .sidebar) // You can change the material to achieve different effects
                .edgesIgnoringSafeArea(.all)
            
            ChatView(colorScheme: _colorScheme)
        }
        .frame(minWidth: 500, idealWidth: 500, maxWidth: .infinity, minHeight: 600, idealHeight: 800, maxHeight: .infinity) // Adjust the frame to make the window longer in height than in width
        .navigationTitle("Claude Companion")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ChatView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var messageText = ""
    @State private var messages: [Message] = []
    @State private var isLoading = false // State variable to track loading

    var body: some View {
        VStack {
            Text("Messages are powered by Claude AI 🤖")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.bottom, 5) // Add padding below the disclaimer
            
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(messages) { message in
                        MessageView(message: message)
                    }
                }
            }
            // Show typing indicator only when loading
            if isLoading {
                TypingIndicator()
            }
            HStack {
                VisualEffectView(material: .sidebar)
                    .frame(height: 30) // Adjust the height of the input box
                    .cornerRadius(15) // Adjust the corner radius to get the desired pill shape
                    .overlay(
                        HStack {
                            TextField("What can I help you with?", text: $messageText, onCommit: sendMessage)
                                .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 0)) // Reduce padding to make the input box smaller
                                .foregroundColor(colorScheme == .dark ? .white : .black) // Set text color based on colorScheme
                                .textFieldStyle(PlainTextFieldStyle()) // Hide default TextFieldStyle
                            
                            if !messageText.isEmpty {
                                Button(action: sendMessage) {
                                    Image(systemName: "paperplane.fill")
                                        .foregroundColor(.white)
                                        .padding(7)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.clear, lineWidth: 1)) // Hide the background
                                }
                                .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 0))
                                .buttonStyle(PlainButtonStyle()) // Hide button style
                            }
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15) // Add the pill shape border
                            .stroke(Color.gray.opacity(0.25), lineWidth: 1) // Set border color and width
                    )
            }
            .padding([.leading, .trailing], 5)
            .padding(.bottom, 10)
        }
        .padding([.top, .leading, .trailing], 5)
    }

    func sendMessage() {
        // Check if the message text is not empty
        guard !messageText.isEmpty else {
            return
        }

        // Store the message text before clearing it
        let userMessageText = messageText

        // Add user's message to the messages array
        let userMessage = Message(text: userMessageText, sender: .user)
        messages.append(userMessage)

        // Clear the message text field immediately
        self.messageText = ""

        // Start loading
        isLoading = true

        // Get response from Claude
        let claudeAPI = ClaudeAPI()
        claudeAPI.getResponseFromClaude(message: userMessageText) { responseData in
            DispatchQueue.main.async {
                // Stop loading
                isLoading = false
            }

            guard let responseData = responseData else {
                DispatchQueue.main.async {
                    let errorMessage = Message(text: "Sorry, I couldn't generate a response.", sender: .claude)
                    self.messages.append(errorMessage)
                }
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any],
                   let content = json["content"] as? [[String: Any]],
                   let messageContent = content.first,
                   let type = messageContent["type"] as? String,
                   type == "text",
                   let responseText = messageContent["text"] as? String {
                    DispatchQueue.main.async {
                        let claudeMessage = Message(text: responseText, sender: .claude)
                        self.messages.append(claudeMessage)
                    }
                } else {
                    DispatchQueue.main.async {
                        let errorMessage = Message(text: "Sorry, I couldn't generate a response.", sender: .claude)
                        self.messages.append(errorMessage)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    let errorMessage = Message(text: "Sorry, I couldn't generate a response.", sender: .claude)
                    self.messages.append(errorMessage)
                }
            }
        }
    }
}

struct MessageView: View {
    let message: Message
    @State private var isAnimating = false // State variable to control the animation

    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer()
                VStack(alignment: .trailing) {
                    Text(message.text)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .scaleEffect(isAnimating ? 1.0 : 0.5) // Scale effect for animation
                        .opacity(isAnimating ? 1.0 : 0.0) // Opacity for animation
                        .animation(.easeInOut, value: isAnimating)
                        .onAppear {
                            // Trigger animation when message appears
                            isAnimating = true
                        }
                }
            } else {
                VStack(alignment: .leading) {
                    Text(message.text)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                        .scaleEffect(isAnimating ? 1.0 : 0.5) // Scale effect for animation
                        .opacity(isAnimating ? 1.0 : 0.0) // Opacity for animation
                        .animation(.easeInOut, value: isAnimating)
                        .onAppear {
                            // Trigger animation when message appears
                            isAnimating = true
                        }
                }
                Spacer()
            }
        }
    }
}

struct Message: Identifiable {
    var id: UUID = UUID()
    var text: String
    var sender: Sender

    enum Sender {
        case user
        case claude
    }
}

struct TypingIndicator: View {
    @State private var dotOpacity: Double = 0.0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .opacity(dotOpacity)
            }
        }
        .onAppear {
            animateDots()
        }
    }

    private func animateDots() {
        withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            dotOpacity = 1.0
        }
    }
}

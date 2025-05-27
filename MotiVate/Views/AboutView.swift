//  AboutView.swift
//  MotiVate
//
//  Created by Chris Venter on 27/5/2025.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Top row: About MotiVate (left), version (right)
            HStack(alignment: .firstTextBaseline) {
                Text("About MotiVate")
                    .font(.title)
                    .bold()
                Spacer()
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                   let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    Text("v\(version) (\(build))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 2)
                }
            }
            .padding(.bottom, 4)

            ScrollView {
                Text("""
Nineteen months ago, my life changed forever. What began as a beautiful evening in Paris during a business trip ended with a catastrophic spinal cord injury that left me paralysed from the shoulders down. In an instant, I went from walking through the streets of Paris to fighting for my life on a cold bathroom floor, barely able to breathe or call for help.

What followed was months of survival, surgeries, intensive care, and the long road of rehabilitation. I endured searing pain, trauma, and moments of hopelessness that nearly broke me. But I also discovered something else: the power of the human spirit to endure.

This app was born from that journey. It’s a simple idea—delivering motivational messages to people who might need a little lift. Messages about courage, pain, perseverance, and perspective. Messages that I find helpful on my darkest days.

I’m not here to tell you I have it all figured out. I still struggle. I still live with pain. But I’ve learned that you can survive almost anything if you break it down into small, bearable pieces. This app is my way of sharing that lesson with anyone who needs to hear it.

I built this entire application without the use of my hands—using a head-tracking Bluetooth mouse, voice commands, and assistive tech that helps me code, create, and connect. If you're curious how that works or just want to follow along with the journey, check out my Instagram at the link below.

If one message, one quote, one image helps you get through a hard day—then it’s all been worth it.

— Chris Venter
""")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 8)
            }

            Divider()

            Text("Connect & Contribute")
                .font(.headline)
                .padding(.bottom, 2)

            VStack(alignment: .leading, spacing: 12) {
                Link(destination: URL(string: "https://github.com/Crypto69/MotiVate")!) {
                    Label("Open Source on GitHub", systemImage: "chevron.left.slash.chevron.right")
                        .labelStyle(IconOnlyLabelStyle())
                        .font(.title2)
                        .foregroundColor(.primary)
                    Text("Open Source on GitHub")
                        .font(.body)
                        .foregroundColor(.accentColor)
                }
                .padding(.vertical, 2)

                Link(destination: URL(string: "https://www.instagram.com/myaccessibility")!) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera") // Instagram SF Symbol fallback
                            .font(.title2)
                            .foregroundColor(.primary)
                        Text("Instagram: @myaccessibility")
                            .font(.body)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.vertical, 2)

                Link(destination: URL(string: "https://www.linkedin.com/in/chris-venter/")!) {
                    HStack(spacing: 8) {
                        Image(systemName: "link") // LinkedIn SF Symbol fallback
                            .font(.title2)
                            .foregroundColor(.primary)
                        Text("LinkedIn: Chris Venter")
                            .font(.body)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.vertical, 2)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 480, height: 600)
    }
}

#Preview {
    AboutView()
}
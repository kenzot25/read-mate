import Cocoa
import SwiftUI

@MainActor
func saveImage(_ view: some View, size: CGSize, path: String) async {
    let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
    renderer.scale = 2.0
    if let nsImage = renderer.nsImage {
        let rep = NSBitmapImageRep(data: nsImage.tiffRepresentation!)
        if let png = rep?.representation(using: .png, properties: [:]) {
            do {
                try png.write(to: URL(fileURLWithPath: path))
                print("Saved \(path)")
            } catch {
                print("Error: \(path) \(error)")
            }
        }
    } else {
        print("Failed: \(path)")
    }
}

struct ShotHUD: View {
    var body: some View {
        ZStack {
            Color.white
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.88, green: 0.88, blue: 0.9), lineWidth: 1)
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles").font(.system(size: 12, weight: .bold)).foregroundColor(.blue)
                    Text("ReadMate").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.18))
                    Spacer()
                    Image(systemName: "xmark").font(.system(size: 9, weight: .bold)).foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.55))
                        .frame(width: 20, height: 20).background(Color(red: 0.92, green: 0.92, blue: 0.94)).clipShape(Circle())
                }
                .padding(.horizontal, 14).frame(height: 40).background(Color(red: 0.97, green: 0.97, blue: 0.98))
                Divider().background(Color(red: 0.9, green: 0.9, blue: 0.92))
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "sparkles").font(.system(size: 32)).foregroundColor(.blue)
                    Text("Select text anywhere & press Cmd+Shift+E")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.18))
                    Text("Or type a word in the text box above to explain instantly.")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.55))
                        .multilineTextAlignment(.center).padding(.horizontal, 40)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 440, height: 420)
    }
}

struct ShotExplain: View {
    var body: some View {
        ZStack {
            Color.white
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.88, green: 0.88, blue: 0.9), lineWidth: 1)
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles").font(.system(size: 12, weight: .bold)).foregroundColor(.blue)
                    Text("ReadMate").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.18))
                    Spacer()
                    Image(systemName: "xmark").font(.system(size: 9, weight: .bold)).foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.55))
                        .frame(width: 20, height: 20).background(Color(red: 0.92, green: 0.92, blue: 0.94)).clipShape(Circle())
                }
                .padding(.horizontal, 14).frame(height: 40).background(Color(red: 0.97, green: 0.97, blue: 0.98))
                Divider().background(Color(red: 0.9, green: 0.9, blue: 0.92))
                VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Text("perseverance")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.12))
                            Spacer()
                            Image(systemName: "speaker.wave.2.bubble.left.fill")
                                .foregroundColor(.blue).font(.system(size: 13))
                                .padding(6).background(Color(red: 0.9, green: 0.93, blue: 1.0)).cornerRadius(6)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("SIMPLE MEANING").font(.system(size: 9, weight: .bold)).foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.55))
                            Text("Continuing to try even when things are difficult; not giving up.")
                                .font(.system(size: 13, weight: .medium)).foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.15))
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("VIETNAMESE").font(.system(size: 9, weight: .bold)).foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.55))
                            Text("Sự kiên trì; không bỏ cuộc dù gặp khó khăn.")
                                .font(.system(size: 13, weight: .semibold)).foregroundColor(Color(red: 0.05, green: 0.15, blue: 0.55))
                        }
                        .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.91, green: 0.94, blue: 1.0)).cornerRadius(8)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NATURAL EXAMPLES").font(.system(size: 9, weight: .bold)).foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.55))
                            HStack(alignment: .top, spacing: 8) {
                                Text("\u{2022}").foregroundColor(.blue)
                                Text("Her perseverance finally paid off when she got the job.")
                                    .font(.system(size: 12, design: .serif)).foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
                                Spacer()
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("\u{2022}").foregroundColor(.blue)
                                Text("Success requires patience and perseverance.")
                                    .font(.system(size: 12, design: .serif)).foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
                                Spacer()
                            }
                        }
                    }
                    .padding(16)
            }
        }
        .frame(width: 440, height: 420)
    }
}

struct ShotButton: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.blue).frame(width: 28, height: 28)
                .shadow(color: Color.blue.opacity(0.35), radius: 4, x: 0, y: 2)
            Circle().stroke(Color.white.opacity(0.5), lineWidth: 1.5).frame(width: 28, height: 28)
            Image(systemName: "sparkles").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
        }
        .frame(width: 60, height: 60).background(Color.clear)
    }
}

Task {
    await saveImage(ShotHUD(), size: CGSize(width: 440, height: 420), path: "screenshots/hud_empty.png")
    await saveImage(ShotExplain(), size: CGSize(width: 440, height: 420), path: "screenshots/hud_explain.png")
    await saveImage(ShotButton(), size: CGSize(width: 60, height: 60), path: "screenshots/floating_button.png")
    print("All done!")
    exit(0)
}

RunLoop.main.run()
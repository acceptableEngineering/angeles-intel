import SwiftUI

struct AudioPlayerBar: View {
    @EnvironmentObject var audioPlayer: AudioPlayerViewModel
    @AppStorage("agencyVerified") private var agencyVerified = false

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 8) {
                streamCell(.forestNet)
                if agencyVerified {
                    Divider()
                        .frame(height: 36)
                    streamCell(.adminNet)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }

    private func streamCell(_ stream: AudioStream) -> some View {
        let state = audioPlayer.streamStates[stream] ?? .stopped
        let playing = state == .playing
        let loading = state == .loading
        let buffering = state == .buffering
        let hot = audioPlayer.isAboveThreshold(stream)

        let isTrailing = stream == .adminNet

        return Button {
            audioPlayer.toggle(stream)
        } label: {
            HStack(spacing: 8) {
                if isTrailing { Spacer(minLength: 0) }

                if !isTrailing {
                    streamIcon(playing: playing, loading: loading, buffering: buffering)
                }

                VStack(alignment: isTrailing ? .trailing : .leading, spacing: 1) {
                    Text(stream.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(hot ? Color.red : Color.primary)
                        .animation(.easeInOut(duration: 0.15), value: hot)
                        .lineLimit(1)

                    Group {
                        if loading {
                            Text("Connecting...")
                        } else if buffering {
                            Text("Buffering...")
                        } else if audioPlayer.errorMessage(for: stream) != nil {
                            Text("Error")
                                .foregroundStyle(.red)
                        } else if playing {
                            HStack(spacing: 4) {
                                if !isTrailing {
                                    Text("Live")
                                        .foregroundStyle(.red)
                                }
                                if let startedAt = audioPlayer.playStartedAt[stream] {
                                    Text(startedAt, style: .timer)
                                        .monospacedDigit()
                                }
                                if isTrailing {
                                    Text("Live")
                                        .foregroundStyle(.red)
                                }
                            }
                        } else {
                            Text("Idle")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                if isTrailing {
                    streamIcon(playing: playing, loading: loading, buffering: buffering)
                }

                if !isTrailing { Spacer(minLength: 0) }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(playing ? Color.accentColor.opacity(0.15) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(loading)
    }

    @ViewBuilder
    private func streamIcon(playing: Bool, loading: Bool, buffering: Bool) -> some View {
        Group {
            if loading || buffering {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                Image(systemName: playing ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
            }
        }
        .frame(width: 36, height: 36)
    }
}

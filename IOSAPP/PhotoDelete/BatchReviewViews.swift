//
//  BatchReviewViews.swift
//  PhotoDelete
//

import SwiftUI
import AVKit
import CoreLocation
import Photos
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 批量确认视图
struct CandidatePreviewAsset: Identifiable {
    let asset: PHAsset

    var id: String {
        asset.localIdentifier
    }
}

func photoPreviewTargetSize(for asset: PHAsset, viewport: CGSize, displayScale: CGFloat) -> CGSize {
    let pixelWidth = max(CGFloat(asset.pixelWidth), 1)
    let pixelHeight = max(CGFloat(asset.pixelHeight), 1)
    let assetLongEdge = max(pixelWidth, pixelHeight)
    let viewportLongEdge = max(viewport.width, viewport.height) * displayScale
    let requestedLongEdge = min(max(viewportLongEdge * 2, 1_600), min(assetLongEdge, 3_200))
    let ratio = requestedLongEdge / assetLongEdge

    return CGSize(
        width: max(pixelWidth * ratio, viewport.width * displayScale),
        height: max(pixelHeight * ratio, viewport.height * displayScale)
    )
}

enum CandidateLivePhotoPreviewPolicy {
    static let networkAccessAllowed = true
    static let deliveryMode: PHImageRequestOptionsDeliveryMode = .highQualityFormat

    static func shouldDisplayLivePhoto(isDegraded: Bool) -> Bool {
        !isDegraded
    }
}

struct ZoomablePhotoPreview: UIViewRepresentable {
    let image: UIImage
    var maximumZoomScale: CGFloat = 5

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = maximumZoomScale
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = context.coordinator

        let imageView = context.coordinator.imageView
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
        context.coordinator.scrollView = scrollView

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        scrollView.maximumZoomScale = maximumZoomScale
        if context.coordinator.image !== image {
            context.coordinator.image = image
            context.coordinator.imageView.image = image
            scrollView.setZoomScale(1, animated: false)
        }
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        let imageView = UIImageView()
        weak var scrollView: UIScrollView?
        weak var image: UIImage?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }

        @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
            guard let scrollView else { return }

            if scrollView.zoomScale > scrollView.minimumZoomScale {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
                return
            }

            let targetScale = min(max(scrollView.minimumZoomScale * 3, 2.5), scrollView.maximumZoomScale)
            let point = recognizer.location(in: imageView)
            let size = CGSize(
                width: scrollView.bounds.width / targetScale,
                height: scrollView.bounds.height / targetScale
            )
            let rect = CGRect(
                x: point.x - size.width / 2,
                y: point.y - size.height / 2,
                width: size.width,
                height: size.height
            )
            scrollView.zoom(to: rect, animated: true)
        }
    }
}

struct PhotoAssetVideoPlayerView: View {
    let asset: PHAsset
    let photoLibraryManager: PhotoLibraryManager
    var autoPlay = true
    var isMuted = true
    var ignoresSafeArea = true
    var allowsPlayerInteraction = false
    var allowsSurfaceTapToRevealControls = true
    var playbackControlsRevealToken: UUID?
    var onScrubbingChanged: (Bool) -> Void = { _ in }

    @State private var player: AVPlayer?
    @State private var requestID: PHImageRequestID?
    @State private var isLoading = true
    @State private var didFail = false
    @State private var loadingAssetIdentifier: String?
    @State private var playbackProgress: Double = 0
    @State private var timeObserverToken: Any?
    @State private var isScrubbingPlayback = false
    @State private var wasPlayingBeforeScrub = false
    @State private var isPlaying = false
    @State private var playbackEndObserver: NSObjectProtocol?
    @State private var showsPlaybackControls = false
    @State private var playbackControlsHideWorkItem: DispatchWorkItem?
    @State private var scrubResumeWorkItem: DispatchWorkItem?

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(edges: ignoresSafeArea ? .all : [])

            if let player {
                ZStack {
                    VideoPlayer(player: player)
                        .ignoresSafeArea(edges: ignoresSafeArea ? .all : [])
                        .allowsHitTesting(allowsPlayerInteraction)

                    if allowsSurfaceTapToRevealControls {
                        VStack(spacing: 0) {
                            VideoPlaybackTapRevealArea {
                                revealPlaybackControls()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            Color.clear
                                .frame(height: VideoPlaybackControlLayout.progressHitHeight)
                                .allowsHitTesting(false)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    if shouldShowPlaybackButton && !isScrubbingPlayback {
                        VideoPlaybackPlayPauseButton(isPlaying: isPlaying) {
                            togglePlayback(for: player)
                        }
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.16), value: isScrubbingPlayback)
                    }
                }
                .contentShape(Rectangle())
                .overlay(alignment: .bottom) {
                    VideoPlaybackProgressBar(
                        progress: playbackProgress,
                        onScrub: seekToProgress,
                        onScrubbingChanged: handlePlaybackScrubbingChanged
                    )
                    .zIndex(2)
                    .allowsHitTesting(true)
                }
                .onAppear {
                    if autoPlay {
                        startPlayback(for: player)
                    }
                }
            } else {
                VStack(spacing: 14) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: PhotoDeleteStyle.accent))
                    } else {
                        Image(systemName: "play.slash")
                            .font(.system(size: 38, weight: .medium))
                            .foregroundColor(PhotoDeleteStyle.secondaryText)
                    }

                    Text(isLoading ? L10n.string("正在读取视频") : L10n.string("无法播放这个视频"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(PhotoDeleteStyle.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
            }
        }
        .onAppear(perform: loadPlayer)
        .onChange(of: isMuted) { muted in
            player?.isMuted = muted
        }
        .onChange(of: playbackControlsRevealToken) { token in
            guard token != nil else { return }
            revealPlaybackControls()
        }
        .onDisappear(perform: cleanup)
    }

    private func loadPlayer() {
        guard player == nil, requestID == nil else { return }

        let requestedAssetID = asset.localIdentifier
        loadingAssetIdentifier = requestedAssetID
        isLoading = true
        didFail = false
        playbackProgress = 0
        showsPlaybackControls = false
        cancelPlaybackControlsAutoHide()

        requestID = photoLibraryManager.loadPlayerItem(for: asset) { playerItem in
            guard loadingAssetIdentifier == requestedAssetID else { return }
            requestID = nil
            isLoading = false

            guard let playerItem else {
                didFail = true
                playbackProgress = 0
                return
            }

            let loadedPlayer = AVPlayer(playerItem: playerItem)
            loadedPlayer.isMuted = isMuted
            player = loadedPlayer
            installPlaybackProgressObserver(for: loadedPlayer)
            installPlaybackEndObserver(for: playerItem)
            if autoPlay {
                startPlayback(for: loadedPlayer)
            }
        }
    }

    private func startPlayback(for player: AVPlayer) {
        player.isMuted = isMuted
        player.play()
        isPlaying = true
        schedulePlaybackControlsAutoHideIfNeeded()
    }

    private func pausePlayback(for player: AVPlayer) {
        player.pause()
        isPlaying = false
        setPlaybackControlsVisible(true, autoHide: false)
    }

    private func togglePlayback(for player: AVPlayer) {
        if isPlaying || player.timeControlStatus == .playing {
            pausePlayback(for: player)
            return
        }

        if playbackProgress >= 0.995 {
            player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
            playbackProgress = 0
        }
        startPlayback(for: player)
    }

    private var shouldShowPlaybackButton: Bool {
        VideoPlaybackControlVisibility.shouldShowButton(
            isPlaying: isPlaying,
            controlsVisible: showsPlaybackControls,
            playbackProgress: playbackProgress
        )
    }

    private func revealPlaybackControls() {
        setPlaybackControlsVisible(true, autoHide: isPlaying)
    }

    private func setPlaybackControlsVisible(_ isVisible: Bool, autoHide: Bool) {
        withAnimation(.easeInOut(duration: 0.16)) {
            showsPlaybackControls = isVisible
        }

        if autoHide {
            schedulePlaybackControlsAutoHideIfNeeded()
        } else {
            cancelPlaybackControlsAutoHide()
        }
    }

    private func schedulePlaybackControlsAutoHideIfNeeded(after delay: TimeInterval = 2.0) {
        cancelPlaybackControlsAutoHide()
        guard VideoPlaybackControlVisibility.shouldAutoHideControls(
            isPlaying: isPlaying,
            controlsVisible: showsPlaybackControls
        ) else {
            return
        }

        let workItem = DispatchWorkItem {
            guard isPlaying else { return }
            guard !isScrubbingPlayback else {
                schedulePlaybackControlsAutoHideIfNeeded(after: VideoPlaybackScrubTiming.controlHideRetryDelay)
                return
            }
            withAnimation(.easeInOut(duration: 0.16)) {
                showsPlaybackControls = false
            }
        }
        playbackControlsHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func cancelPlaybackControlsAutoHide() {
        playbackControlsHideWorkItem?.cancel()
        playbackControlsHideWorkItem = nil
    }

    private func installPlaybackProgressObserver(for loadedPlayer: AVPlayer) {
        removePlaybackProgressObserver()
        playbackProgress = 0
        timeObserverToken = loadedPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak loadedPlayer] time in
            guard let currentPlayer = loadedPlayer else { return }
            guard !isScrubbingPlayback else { return }
            guard let duration = VideoPlaybackDurationResolver.playableDuration(
                playerItemDuration: currentPlayer.currentItem?.duration.seconds,
                assetDuration: asset.duration
            ),
                  time.seconds.isFinite else {
                playbackProgress = 0
                return
            }
            playbackProgress = min(max(time.seconds / duration, 0), 1)
        }
    }

    private func removePlaybackProgressObserver() {
        guard let timeObserverToken else { return }
        player?.removeTimeObserver(timeObserverToken)
        self.timeObserverToken = nil
    }

    private func installPlaybackEndObserver(for playerItem: AVPlayerItem) {
        removePlaybackEndObserver()
        playbackEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            playbackProgress = 1
            isPlaying = false
            setPlaybackControlsVisible(true, autoHide: false)
        }
    }

    private func removePlaybackEndObserver() {
        guard let playbackEndObserver else { return }
        NotificationCenter.default.removeObserver(playbackEndObserver)
        self.playbackEndObserver = nil
    }

    private func handlePlaybackScrubbingChanged(_ isScrubbing: Bool) {
        guard isScrubbingPlayback != isScrubbing else { return }
        isScrubbingPlayback = isScrubbing
        onScrubbingChanged(isScrubbing)

        if isScrubbing {
            cancelScrubResume()
            setPlaybackControlsVisible(true, autoHide: false)
            wasPlayingBeforeScrub = VideoPlaybackScrubResumePolicy.shouldResumeAfterScrub(
                wasPlayingState: isPlaying,
                playerWasPlaying: player?.timeControlStatus == .playing,
                autoPlayEnabled: autoPlay,
                playbackProgress: playbackProgress
            )
            player?.pause()
            isPlaying = false
        } else if VideoPlaybackScrubResumePolicy.shouldResumeAfterScrub(
            wasPlayingState: wasPlayingBeforeScrub,
            playerWasPlaying: player?.timeControlStatus == .playing,
            autoPlayEnabled: autoPlay,
            playbackProgress: playbackProgress
        ) {
            if let player {
                cancelScrubResume()
                startPlayback(for: player)
                schedulePlaybackControlsAutoHideIfNeeded(after: VideoPlaybackScrubTiming.controlHideAfterResumeDelay)
            }
            wasPlayingBeforeScrub = false
        } else {
            isPlaying = player?.timeControlStatus == .playing
            setPlaybackControlsVisible(true, autoHide: isPlaying)
        }
    }

    private func seekToProgress(_ progress: Double) {
        guard let player,
              let duration = VideoPlaybackDurationResolver.playableDuration(
                playerItemDuration: player.currentItem?.duration.seconds,
                assetDuration: asset.duration
              ) else {
            return
        }

        let clampedProgress = VideoPlaybackProgressMapper.clamped(progress)
        playbackProgress = clampedProgress
        player.seek(
            to: CMTime(seconds: duration * clampedProgress, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
        schedulePlaybackResumeAfterScrubSeek()
    }

    private func schedulePlaybackResumeAfterScrubSeek() {
        guard autoPlay, playbackProgress < 0.995 else { return }
        scrubResumeWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            guard autoPlay,
                  playbackProgress < 0.995,
                  let player else {
                return
            }
            if isScrubbingPlayback {
                isScrubbingPlayback = false
                onScrubbingChanged(false)
            }
            wasPlayingBeforeScrub = false
            startPlayback(for: player)
            schedulePlaybackControlsAutoHideIfNeeded(after: VideoPlaybackScrubTiming.controlHideAfterResumeDelay)
            scrubResumeWorkItem = nil
        }
        scrubResumeWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + VideoPlaybackScrubTiming.resumeAfterLastScrubDelay,
            execute: workItem
        )
    }

    private func cancelScrubResume() {
        scrubResumeWorkItem?.cancel()
        scrubResumeWorkItem = nil
    }

    private func cleanup() {
        photoLibraryManager.cancelImageRequest(requestID)
        requestID = nil
        loadingAssetIdentifier = nil
        removePlaybackProgressObserver()
        removePlaybackEndObserver()
        cancelPlaybackControlsAutoHide()
        cancelScrubResume()
        player?.pause()
        player = nil
        playbackProgress = 0
        isPlaying = false
        showsPlaybackControls = false
        if isScrubbingPlayback {
            onScrubbingChanged(false)
        }
        isScrubbingPlayback = false
        wasPlayingBeforeScrub = false
    }
}

enum VideoPlaybackProgressMapper {
    static func clamped(_ progress: Double) -> Double {
        min(max(progress, 0), 1)
    }

    static func progress(locationX: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return 0 }
        return clamped(Double(locationX / width))
    }
}

enum VideoPlaybackDurationResolver {
    static func playableDuration(playerItemDuration: Double?, assetDuration: TimeInterval) -> Double? {
        if let playerItemDuration,
           playerItemDuration.isFinite,
           playerItemDuration > 0 {
            return playerItemDuration
        }

        guard assetDuration.isFinite, assetDuration > 0 else { return nil }
        return assetDuration
    }
}

enum VideoPlaybackControlLayout {
    static let progressHitHeight: CGFloat = 54
    static let progressHorizontalPadding: CGFloat = 14

    static func isInProgressHitRegion(point: CGPoint, containerSize: CGSize) -> Bool {
        guard containerSize.width > 0,
              containerSize.height > 0,
              progressHitHeight > 0 else {
            return false
        }

        let progressTop = max(containerSize.height - progressHitHeight, 0)
        return point.x >= 0 &&
            point.x <= containerSize.width &&
            point.y >= progressTop &&
            point.y <= containerSize.height
    }
}

enum VideoPlaybackScrubResumePolicy {
    static func shouldResumeAfterScrub(
        wasPlayingState: Bool,
        playerWasPlaying: Bool,
        autoPlayEnabled: Bool = false,
        playbackProgress: Double = 0
    ) -> Bool {
        wasPlayingState || playerWasPlaying || (autoPlayEnabled && playbackProgress < 0.995)
    }
}

enum VideoPlaybackScrubTiming {
    static let endFallbackDelay: TimeInterval = 0.18
    static let resumeAfterLastScrubDelay: TimeInterval = 0.24
    static let controlHideRetryDelay: TimeInterval = 0.25
    static let controlHideAfterResumeDelay: TimeInterval = 0.45
}

enum VideoPlaybackControlVisibility {
    static func shouldShowButton(isPlaying: Bool, controlsVisible: Bool, playbackProgress: Double) -> Bool {
        controlsVisible || !isPlaying || playbackProgress >= 0.995
    }

    static func shouldAutoHideControls(isPlaying: Bool, controlsVisible: Bool) -> Bool {
        isPlaying && controlsVisible
    }
}

private struct VideoPlaybackPlayPauseButton: View {
    let isPlaying: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(
                L10n.string(isPlaying ? "暂停视频" : "播放视频"),
                systemImage: isPlaying ? "pause.fill" : "play.fill"
            )
            .labelStyle(.iconOnly)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 50, height: 50)
            .background(Circle().fill(Color.black.opacity(0.62)))
            .overlay(Circle().stroke(Color.white.opacity(0.24), lineWidth: 1))
            .shadow(color: .black.opacity(0.28), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .photoDeleteMinimumTapTarget()
        .accessibilityIdentifier("video-playback-toggle-button")
        .accessibilityLabel(L10n.string(isPlaying ? "暂停视频" : "播放视频"))
    }
}

private struct VideoPlaybackTapRevealArea: View {
    let action: () -> Void

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded { action() }, including: .gesture)
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("photo-asset-video-player")
            .accessibilityLabel(L10n.string("视频预览"))
            .accessibilityAddTraits(.isButton)
    }
}

private struct VideoPlaybackProgressBar: View {
    let progress: Double
    let onScrub: (Double) -> Void
    let onScrubbingChanged: (Bool) -> Void

    @State private var scrubbingProgress: Double?

    private var displayedProgress: Double {
        VideoPlaybackProgressMapper.clamped(scrubbingProgress ?? progress)
    }

    var body: some View {
        VideoPlaybackSlider(
            progress: displayedProgress,
            onScrub: updateScrubProgress,
            onScrubbingChanged: handleSliderEditingChanged
        )
        .frame(height: VideoPlaybackControlLayout.progressHitHeight)
        .padding(.horizontal, VideoPlaybackControlLayout.progressHorizontalPadding)
        .background(
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.46)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.string("视频预览"))
        .accessibilityValue(L10n.percent(Int(displayedProgress * 100)))
        .accessibilityIdentifier("video-playback-progress-bar")
    }

    private func updateScrubProgress(_ progress: Double) {
        let clampedProgress = VideoPlaybackProgressMapper.clamped(progress)
        if scrubbingProgress == nil {
            onScrubbingChanged(true)
        }
        scrubbingProgress = clampedProgress
        onScrub(clampedProgress)
    }

    private func handleSliderEditingChanged(_ isEditing: Bool) {
        if isEditing {
            if scrubbingProgress == nil {
                onScrubbingChanged(true)
            }
            return
        }

        if let scrubbingProgress {
            onScrub(scrubbingProgress)
        }
        scrubbingProgress = nil
        onScrubbingChanged(false)
    }
}

#if canImport(UIKit)
private struct VideoPlaybackSlider: UIViewRepresentable {
    let progress: Double
    let onScrub: (Double) -> Void
    let onScrubbingChanged: (Bool) -> Void

    func makeUIView(context: Context) -> UISlider {
        let slider = ScrubbableSlider(frame: .zero)
        slider.accessibilityIdentifier = "video-playback-slider"
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.isContinuous = true
        slider.minimumTrackTintColor = UIColor(PhotoDeleteStyle.accent)
        slider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.28)
        slider.setThumbImage(Self.thumbImage(diameter: 20), for: .normal)
        slider.setThumbImage(Self.thumbImage(diameter: 24), for: .highlighted)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.touchDown(_:)), for: .touchDown)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.touchEnded(_:)),
            for: [.touchUpInside, .touchUpOutside, .touchCancel]
        )

        slider.value = Float(VideoPlaybackProgressMapper.clamped(progress))
        return slider
    }

    func updateUIView(_ slider: UISlider, context: Context) {
        context.coordinator.parent = self
        slider.minimumTrackTintColor = UIColor(PhotoDeleteStyle.accent)
        slider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.28)

        guard !slider.isTracking else { return }
        slider.value = Float(VideoPlaybackProgressMapper.clamped(progress))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    static func dismantleUIView(_ slider: UISlider, coordinator: Coordinator) {
        coordinator.forceEndScrubbing()
    }

    private static func thumbImage(diameter: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter))
        return renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
            context.cgContext.setShadow(
                offset: CGSize(width: 0, height: 1),
                blur: 4,
                color: UIColor.black.withAlphaComponent(0.28).cgColor
            )
            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: rect.insetBy(dx: 2, dy: 2))
        }
    }

    private final class ScrubbableSlider: UISlider {
        private let minimumTouchHeight: CGFloat = 54

        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            let verticalInset = max(0, (minimumTouchHeight - bounds.height) / 2)
            return bounds.insetBy(dx: 0, dy: -verticalInset).contains(point)
        }

        override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
            updateValue(for: touch)
            sendActions(for: .touchDown)
            sendActions(for: .valueChanged)
            return true
        }

        override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
            updateValue(for: touch)
            sendActions(for: .valueChanged)
            return true
        }

        override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
            if let touch {
                updateValue(for: touch)
                sendActions(for: .valueChanged)
            }
            sendActions(for: .touchUpInside)
            super.endTracking(touch, with: event)
        }

        override func cancelTracking(with event: UIEvent?) {
            sendActions(for: .touchCancel)
            super.cancelTracking(with: event)
        }

        private func updateValue(for touch: UITouch) {
            let progress = VideoPlaybackProgressMapper.progress(
                locationX: touch.location(in: self).x,
                width: bounds.width
            )
            value = Float(progress)
        }
    }

    final class Coordinator: NSObject {
        var parent: VideoPlaybackSlider
        private var isScrubbing = false
        private var scrubEndFallbackWorkItem: DispatchWorkItem?

        init(parent: VideoPlaybackSlider) {
            self.parent = parent
        }

        @objc func touchDown(_ slider: UISlider) {
            beginScrubbing()
            parent.onScrub(Double(slider.value))
        }

        @objc func valueChanged(_ slider: UISlider) {
            beginScrubbing()
            scheduleScrubEndFallback()
            parent.onScrub(Double(slider.value))
        }

        @objc func touchEnded(_ slider: UISlider) {
            parent.onScrub(Double(slider.value))
            endScrubbing()
        }

        private func beginScrubbing() {
            guard !isScrubbing else { return }
            isScrubbing = true
            parent.onScrubbingChanged(true)
        }

        private func endScrubbing() {
            scrubEndFallbackWorkItem?.cancel()
            scrubEndFallbackWorkItem = nil
            guard isScrubbing else { return }
            isScrubbing = false
            parent.onScrubbingChanged(false)
        }

        func forceEndScrubbing() {
            endScrubbing()
        }

        private func scheduleScrubEndFallback() {
            scrubEndFallbackWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.endScrubbing()
            }
            scrubEndFallbackWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + VideoPlaybackScrubTiming.endFallbackDelay, execute: workItem)
        }
    }
}
#endif

struct CandidatePhotoPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    let asset: PHAsset
    let photoLibraryManager: PhotoLibraryManager
    var locationTitle: String? = nil

    @State private var image: UIImage?
    @State private var livePhoto: PHLivePhoto?
    @State private var isLoading = true
    @State private var imageRequestID: PHImageRequestID?
    @State private var livePhotoRequestID: PHImageRequestID?
    @State private var failedToLoadLivePhoto = false
    @State private var sharePayload: PhotoSharePayload?
    @State private var sharePreparationTask: Task<Void, Never>?
    @State private var isPreparingShare = false
    @State private var showShareError = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        previewMedia(in: geometry.size)
                            .frame(height: previewMediaHeight(in: geometry.size))

                        PhotoAssetDetailsPanel(
                            asset: asset,
                            photoLibraryManager: photoLibraryManager,
                            locationTitle: locationTitle
                        )
                        .padding(.horizontal, PhotoDeleteStyle.screenHorizontalPadding)
                        .padding(.top, 18)
                        .padding(.bottom, 32)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height, alignment: .top)
                }
                .background(PhotoDeleteStyle.background.ignoresSafeArea())
                .onAppear {
                    if isLivePhotoAsset {
                        loadImage(in: geometry.size)
                        loadLivePhoto(in: geometry.size)
                    } else if asset.mediaType != .video {
                        loadImage(in: geometry.size)
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: prepareShare) {
                        Group {
                            if isPreparingShare {
                                ProgressView()
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                        .frame(width: 44, height: 44)
                    }
                    .disabled(isPreparingShare)
                    .accessibilityLabel(L10n.string("分享"))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.string("关闭")) {
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $sharePayload, onDismiss: cleanupSharePayload) { payload in
            SystemShareSheet(activityItems: [payload.fileURL])
        }
        .alert(L10n.string("操作失败，请稍后重试。"), isPresented: $showShareError) {
            Button(L10n.string("知道了"), role: .cancel) {}
        }
        .onDisappear {
            photoLibraryManager.cancelImageRequest(imageRequestID)
            photoLibraryManager.cancelImageRequest(livePhotoRequestID)
            sharePreparationTask?.cancel()
            sharePreparationTask = nil
            isPreparingShare = false
        }
    }

    @ViewBuilder
    private func previewMedia(in size: CGSize) -> some View {
        ZStack {
            PhotoDeleteStyle.background

            if asset.mediaType == .video {
                PhotoAssetVideoPlayerView(
                    asset: asset,
                    photoLibraryManager: photoLibraryManager,
                    ignoresSafeArea: false
                )
            } else if isLivePhotoAsset {
                if let livePhoto {
                    LivePhotoPreviewRepresentable(
                        livePhoto: livePhoto,
                        contentIdentifier: asset.localIdentifier
                    )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityLabel(L10n.string("实况照片"))
                } else if let image {
                    ZoomablePhotoPreview(image: image)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityLabel(L10n.string("放大的照片"))
                } else {
                    loadingContent
                }
            } else if let image {
                ZoomablePhotoPreview(image: image)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel(L10n.string("放大的照片"))
            } else {
                loadingContent
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(asset.mediaType == .video ? 1 : 0.08))
    }

    private func previewMediaHeight(in size: CGSize) -> CGFloat {
        min(max(size.height * 0.82, 420), size.height * 0.88)
    }

    private var isLivePhotoAsset: Bool {
        photoLibraryManager.isLivePhoto(asset)
    }

    private var navigationTitle: String {
        if asset.mediaType == .video {
            return L10n.string("视频预览")
        }
        if isLivePhotoAsset {
            return L10n.string("实况照片")
        }
        return L10n.string("照片预览")
    }

    private var loadingContent: some View {
        VStack(spacing: 14) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: PhotoDeleteStyle.accent))
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(PhotoDeleteStyle.secondaryText)
            }

            Text(isLoading ? L10n.string("正在读取照片") : L10n.string("无法读取这张照片"))
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(PhotoDeleteStyle.secondaryText)
        }
    }

    private func loadLivePhoto(in size: CGSize) {
        guard livePhotoRequestID == nil, livePhoto == nil, !failedToLoadLivePhoto else { return }
        isLoading = true
        let targetSize = photoPreviewTargetSize(for: asset, viewport: size, displayScale: displayScale)

        livePhotoRequestID = photoLibraryManager.loadLivePhotoResult(
            for: asset,
            size: targetSize,
            networkAccessAllowed: CandidateLivePhotoPreviewPolicy.networkAccessAllowed,
            deliveryMode: CandidateLivePhotoPreviewPolicy.deliveryMode
        ) { result in
            if let loadedLivePhoto = result.livePhoto,
               CandidateLivePhotoPreviewPolicy.shouldDisplayLivePhoto(isDegraded: result.isDegraded) {
                livePhoto = loadedLivePhoto
                isLoading = false
            } else if result.isFinal {
                failedToLoadLivePhoto = true
                isLoading = image == nil
            }

            if result.isFinal {
                livePhotoRequestID = nil
            }
        }
    }

    private func loadImage(in size: CGSize) {
        guard imageRequestID == nil, image == nil else { return }
        isLoading = true
        let targetSize = photoPreviewTargetSize(for: asset, viewport: size, displayScale: displayScale)

        imageRequestID = photoLibraryManager.loadHighQualityPreview(
            for: asset,
            size: targetSize,
            networkAccessAllowed: true
        ) { loadedImage in
            image = loadedImage
            isLoading = false
            imageRequestID = nil
        }
    }

    private func prepareShare() {
        guard !isPreparingShare else { return }

        isPreparingShare = true
        sharePreparationTask?.cancel()
        sharePreparationTask = Task {
            do {
                let payload = try await photoLibraryManager.prepareSharePayload(for: asset)
                guard !Task.isCancelled else {
                    payload.cleanup()
                    return
                }
                await MainActor.run {
                    sharePayload = payload
                    isPreparingShare = false
                    sharePreparationTask = nil
                }
            } catch is CancellationError {
                await MainActor.run {
                    isPreparingShare = false
                    sharePreparationTask = nil
                }
            } catch {
                await MainActor.run {
                    isPreparingShare = false
                    sharePreparationTask = nil
                    showShareError = true
                }
            }
        }
    }

    private func cleanupSharePayload() {
        sharePayload?.cleanup()
        sharePayload = nil
    }
}

private struct PhotoAssetDetailsPanel: View {
    let asset: PHAsset
    let photoLibraryManager: PhotoLibraryManager
    var locationTitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(PhotoDeleteStyle.accent)

                Text(L10n.string("照片信息"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(PhotoDeleteStyle.primaryText)
            }

            VStack(spacing: 0) {
                detailRow(label: L10n.string("拍摄时间"), value: captureDateText, icon: "calendar")
                if let locationText {
                    detailDivider
                    detailRow(label: L10n.string("地点"), value: locationText, icon: "location")
                }
                if let modificationDateText {
                    detailDivider
                    detailRow(label: L10n.string("修改时间"), value: modificationDateText, icon: "clock.arrow.circlepath")
                }
                if let sourceText {
                    detailDivider
                    detailRow(label: L10n.string("图库来源"), value: sourceText, icon: "photo.stack")
                }
                if let originalFilenameText {
                    detailDivider
                    detailRow(label: L10n.string("原始文件名"), value: originalFilenameText, icon: "doc.text")
                }
                Divider().background(PhotoDeleteStyle.hairline).padding(.leading, 44)
                detailRow(label: L10n.string("类型"), value: mediaTypeText, icon: mediaTypeIcon)
                Divider().background(PhotoDeleteStyle.hairline).padding(.leading, 44)
                detailRow(label: L10n.string("尺寸"), value: pixelSizeText, icon: "aspectratio")
                Divider().background(PhotoDeleteStyle.hairline).padding(.leading, 44)
                detailRow(label: L10n.string("方向"), value: orientationText, icon: "rectangle")

                if asset.mediaType == .video {
                    Divider().background(PhotoDeleteStyle.hairline).padding(.leading, 44)
                    detailRow(label: L10n.string("时长"), value: durationText, icon: "clock")
                }

                if asset.isFavorite {
                    Divider().background(PhotoDeleteStyle.hairline).padding(.leading, 44)
                    detailRow(label: L10n.string("状态"), value: L10n.string("已收藏"), icon: "heart.fill")
                }
            }
            .photoDeleteCard()
        }
        .accessibilityElement(children: .contain)
    }

    private var detailDivider: some View {
        Divider().background(PhotoDeleteStyle.hairline).padding(.leading, 44)
    }

    private func detailRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            PhotoDeleteIconTile(icon: icon, tint: PhotoDeleteStyle.accent, size: 32, cornerRadius: 10)

            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(PhotoDeleteStyle.tertiaryText)

                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(PhotoDeleteStyle.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var captureDateText: String {
        PhotoAssetMetadataFormatter.detailCaptureDate(for: asset.creationDate)
    }

    private var locationText: String? {
        PhotoAssetMetadataFormatter.optionalLocationText(
            locationTitle: locationTitle,
            coordinate: asset.location?.coordinate
        )
    }

    private var modificationDateText: String? {
        guard let modificationDate = asset.modificationDate else { return nil }
        return AppDateFormatter.string(from: modificationDate, dateStyle: .medium, timeStyle: .short)
    }

    private var sourceText: String? {
        PhotoAssetSourceFormatter.sourceDescription(for: asset.sourceType)
    }

    private var originalFilenameText: String? {
        PhotoAssetSourceFormatter.originalFilename(for: asset)
    }

    private var mediaTypeText: String {
        if asset.mediaType == .video {
            return L10n.string("视频")
        }
        if photoLibraryManager.isLivePhoto(asset) {
            return L10n.string("实况照片")
        }
        if photoLibraryManager.isScreenshot(asset) {
            return L10n.string("截图")
        }
        return L10n.string("照片")
    }

    private var mediaTypeIcon: String {
        if asset.mediaType == .video { return "video" }
        if photoLibraryManager.isLivePhoto(asset) { return "livephoto" }
        if photoLibraryManager.isScreenshot(asset) { return "camera.viewfinder" }
        return "photo"
    }

    private var pixelSizeText: String {
        guard asset.pixelWidth > 0, asset.pixelHeight > 0 else {
            return L10n.string("未知")
        }
        return "\(asset.pixelWidth) × \(asset.pixelHeight)"
    }

    private var orientationText: String {
        guard asset.pixelWidth > 0, asset.pixelHeight > 0 else {
            return L10n.string("未知")
        }
        if asset.pixelWidth > asset.pixelHeight {
            return L10n.string("横向")
        }
        if asset.pixelHeight > asset.pixelWidth {
            return L10n.string("竖向")
        }
        return L10n.string("方形")
    }

    private var durationText: String {
        let totalSeconds = max(Int(asset.duration.rounded()), 0)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct LivePhotoPreviewRepresentable: UIViewRepresentable {
    let livePhoto: PHLivePhoto
    let contentIdentifier: String
    var autoPlay = true
    var isMuted = true
    var playbackStyle: PHLivePhotoViewPlaybackStyle = .full
    var playbackTrigger = 0
    var contentMode: UIView.ContentMode = .scaleAspectFit

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PHLivePhotoView {
        let view = PHLivePhotoView()
        view.contentMode = contentMode
        view.isMuted = isMuted
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: PHLivePhotoView, context: Context) {
        let shouldStartPlayback = context.coordinator.playbackRequestState.shouldStartPlayback(
            contentIdentifier: contentIdentifier,
            autoPlay: autoPlay,
            playbackTrigger: playbackTrigger
        )
        context.coordinator.autoPlay = autoPlay
        context.coordinator.playbackStyle = playbackStyle
        context.coordinator.isDismantled = false
        uiView.contentMode = contentMode
        uiView.isMuted = isMuted

        if !autoPlay {
            context.coordinator.stopPlayback(in: uiView)
        }

        if context.coordinator.displayedLivePhoto !== livePhoto {
            context.coordinator.displayedLivePhoto = livePhoto
            uiView.livePhoto = livePhoto
        }

        if shouldStartPlayback {
            context.coordinator.startPlayback(in: uiView, delay: 0.12)
        }
    }

    static func dismantleUIView(_ uiView: PHLivePhotoView, coordinator: Coordinator) {
        coordinator.isDismantled = true
        coordinator.cancelPendingPlayback()
        uiView.delegate = nil
        uiView.stopPlayback()
        uiView.livePhoto = nil
        coordinator.displayedLivePhoto = nil
    }

    final class Coordinator: NSObject, PHLivePhotoViewDelegate {
        weak var displayedLivePhoto: PHLivePhoto?
        var autoPlay = false
        var playbackStyle: PHLivePhotoViewPlaybackStyle = .full
        var playbackRequestState = LivePhotoPlaybackRequestState()
        var isPlaying = false
        var isDismantled = false
        private var pendingPlaybackToken: UUID?

        func startPlayback(in view: PHLivePhotoView, delay: TimeInterval) {
            guard autoPlay else { return }
            let playbackToken = UUID()
            pendingPlaybackToken = playbackToken
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak view] in
                guard let self,
                      let view,
                      self.pendingPlaybackToken == playbackToken,
                      self.autoPlay,
                      !self.isDismantled,
                      view.livePhoto != nil else { return }
                self.pendingPlaybackToken = nil
                view.stopPlayback()
                view.startPlayback(with: self.playbackStyle)
                self.isPlaying = true
            }
        }

        func cancelPendingPlayback() {
            pendingPlaybackToken = nil
        }

        func stopPlayback(in view: PHLivePhotoView) {
            cancelPendingPlayback()
            view.stopPlayback()
            isPlaying = false
        }

        func livePhotoView(_ livePhotoView: PHLivePhotoView, willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
            isPlaying = true
        }

        func livePhotoView(_ livePhotoView: PHLivePhotoView, didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
            isPlaying = false
        }
    }
}

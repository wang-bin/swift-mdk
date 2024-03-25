//
//  Player.swift
//
//  Created by WangBin on 2020/12/1.
//
#if canImport(mdk)
import mdk
#endif

import MetalKit
// https://stackoverflow.com/questions/43880839/swift-unable-to-cast-function-pointer-to-void-for-use-in-c-style-third-party
// https://stackoverflow.com/questions/37401959/how-can-i-get-the-memory-address-of-a-value-type-or-a-custom-struct-in-swift
// https://stackoverflow.com/questions/33294620/how-to-cast-self-to-unsafemutablepointervoid-type-in-swift
import Foundation // needed for strdup and free

public enum MapDirection : UInt32 {
    case FrameToViewport
    case ViewportToFrame
}

// for char* const []
internal func withArrayOfCStrings<R>(
    _ args: [String],
    _ body: ([UnsafeMutablePointer<CChar>?]) -> R
) -> R {
    var cStrings = args.map { strdup($0) }
    cStrings.append(nil)
    defer {
        cStrings.forEach { free($0) }
    }
    return body(cStrings)
}

internal func bridge<T : AnyObject>(obj : T?) -> UnsafeRawPointer? {
    guard let o = obj else {
        return nil
    }
    return UnsafeRawPointer(Unmanaged.passUnretained(o).toOpaque())
}

internal func bridge<T : AnyObject>(obj : T?) -> UnsafeMutableRawPointer? {
    guard let o = obj else {
        return nil
    }
    return UnsafeMutableRawPointer(Unmanaged.passUnretained(o).toOpaque())
}

internal func bridge<T : AnyObject>(ptr : UnsafeRawPointer) -> T {
    return Unmanaged<T>.fromOpaque(ptr).takeUnretainedValue()
}


public class Player {
    public var mute = false {
        didSet {
            player.pointee.setMute(player.pointee.object, mute)
        }
    }

    public var volume:Float = 1.0 {
        didSet {
            player.pointee.setVolume(player.pointee.object, volume)
        }
    }

    public var media = "" {
        didSet {
            player.pointee.setMedia(player.pointee.object, media)
        }
    }

    // audioDecoders
    public var audioDecoders = ["FFmpeg"] {
        didSet {
            withArrayOfCStrings(audioDecoders) {
                //let ptr = UnsafeMutablePointer<UnsafePointer<Int8>?>(OpaquePointer($0))
                // TODO: ends with nullptr
                $0.withUnsafeBufferPointer({
                    let ptr = UnsafeMutablePointer<UnsafePointer<Int8>?>(OpaquePointer($0.baseAddress))
                    player.pointee.setDecoders(player.pointee.object, MDK_MediaType_Audio, ptr)
                })
            }
        }
    }

    public var videoDecoders = ["FFmpeg"] {
        didSet {
            withArrayOfCStrings(videoDecoders) {
                //let ptr = UnsafeMutablePointer<UnsafePointer<Int8>?>(OpaquePointer($0))
                $0.withUnsafeBufferPointer({
                    let ptr = UnsafeMutablePointer<UnsafePointer<Int8>?>(OpaquePointer($0.baseAddress))
                    player.pointee.setDecoders(player.pointee.object, MDK_MediaType_Video, ptr)
                })
            }
        }
    }

    public var activeAudioTracks = [0] {
        didSet {
            setActiveTracks(type: .Audio, tracks: activeAudioTracks)
        }
    }

    public var activeVideoTracks = [0] {
        didSet {
            setActiveTracks(type: .Video, tracks: activeVideoTracks)
        }
    }

    public var activeSubtitleTracks = [0] {
        didSet {
            setActiveTracks(type: .Subtitle, tracks: activeSubtitleTracks)
        }
    }

    public var state:State = .Stopped {
        didSet {
            player.pointee.setState(player.pointee.object, MDK_State(state.rawValue))
        }
    }

    public var mediaStatus : MediaStatus {
        MediaStatus(rawValue: player.pointee.mediaStatus(player.pointee.object).rawValue)
    }

    public var loop:Int32 = 0 {
        didSet {
            player.pointee.setLoop(player.pointee.object, loop)
        }
    }

    public var preloadImmediately = true {
        didSet {
            player.pointee.setPreloadImmediately(player.pointee.object, preloadImmediately)
        }
    }

    public var position : Int64 {
        player.pointee.position(player.pointee.object)
    }

    public var playbackRate : Float = 1.0 {
        didSet {
            player.pointee.setPlaybackRate(player.pointee.object, playbackRate)
        }
    }

    public var mediaInfo : MediaInfo {
        from(c:player.pointee.mediaInfo(player.pointee.object), to:&info)
        return info
    }


    public func setRenderAPI(_ api :  UnsafePointer<mdkMetalRenderAPI>, vid:AnyObject? = nil) ->Void {
        player.pointee.setRenderAPI(player.pointee.object, OpaquePointer(api), bridge(obj: vid))
    }
    
    // TODO: addRenderTarget, removeRenderTarget
    @available(visionOS, unavailable)
    public func setRenderTarget(_ mkv : MTKView, commandQueue cmdQueue: MTLCommandQueue, vid:AnyObject? = nil) ->Void {
        func currentRt(_ opaque: UnsafeRawPointer?)->UnsafeRawPointer? {
            guard let p = opaque else {
                return nil
            }
            let v : MTKView = bridge(ptr: p)
            guard let drawable = v.currentDrawable else {
                return nil
            }
            return bridge(obj: drawable.texture)
        }

        var ra = mdkMetalRenderAPI()
        ra.type = MDK_RenderAPI_Metal
        ra.device = bridge(obj: mkv.device.unsafelyUnwrapped)
        ra.cmdQueue = bridge(obj: cmdQueue)
        ra.opaque = bridge(obj: mkv)
        ra.currentRenderTarget = currentRt
        ra.layer = bridge(obj: mkv.layer)
        setRenderAPI(&ra, vid:vid)
    }

    @available(visionOS, unavailable)
    public func addRenderTarget(_ mkv : MTKView, commandQueue cmdQueue: MTLCommandQueue) -> Void {
        setRenderTarget(mkv, commandQueue: cmdQueue, vid: mkv)
    }

    public func setVideoSurfaceSize(_ width : CGFloat, _ height : CGFloat, vid:AnyObject? = nil)->Void {
        player.pointee.setVideoSurfaceSize(player.pointee.object, Int32(width), Int32(height), bridge(obj: vid))
    }

    public func renderVideo(vid:AnyObject? = nil) -> Double {
        return player.pointee.renderVideo(player.pointee.object, bridge(obj: vid))
    }

    public func set(media:String, forType type:MediaType) {
        player.pointee.setMediaForType(player.pointee.object, media, MDK_MediaType(type.rawValue))
    }

    public func setNext(media:String, from:Int64 = 0, withSeekFlag flag:SeekFlag = .Default) {
        player.pointee.setNextMedia(player.pointee.object, media, from, MDKSeekFlag(flag.rawValue))
    }

    public func currentMediaChanged(_ callback:(()->Void)?) {
        func f_(opaque:UnsafeMutableRawPointer?) {
            let obj = Unmanaged<Player>.fromOpaque(opaque!).takeUnretainedValue()
            obj.current_cb_?()
        }
        current_cb_ = callback
        var cb = mdkCurrentMediaChangedCallback()
        cb.cb = f_
        if callback != nil {
            cb.opaque = bridge(obj: self)!
        }
        player.pointee.currentMediaChanged(player.pointee.object, cb)
    }

    public func setTimeout(_ value:Int64, callback:((Int64)->Bool)?) -> Void {
        func f_(value:Int64, opaque:UnsafeMutableRawPointer?)->Bool {
            let obj = Unmanaged<Player>.fromOpaque(opaque!).takeUnretainedValue()
            return obj.timeout_cb_!(value)
        }
        timeout_cb_ = callback
        var cb = mdkTimeoutCallback()
        cb.cb = f_
        if callback != nil {
            cb.opaque = bridge(obj: self)!
        }
        player.pointee.setTimeout(player.pointee.object, value, cb)
    }

    public func prepare(from:Int64, complete:((Int64, inout Bool)->Bool)?, _ flag:SeekFlag = .Default) {
        func f_(pos:Int64, boost:UnsafeMutablePointer<Bool>?, opaque:UnsafeMutableRawPointer?)->Bool {
            let obj = Unmanaged<Player>.fromOpaque(opaque!).takeUnretainedValue()
            var _boost = true
            let ret = obj.prepare_cb_!(pos, &_boost)
            boost?.update(repeating: _boost, count: 1)
            return ret
        }
        prepare_cb_ = complete
        var cb = mdkPrepareCallback()
        cb.cb = f_
        if complete != nil {
            cb.opaque = bridge(obj: self)!
        }
        player.pointee.prepare(player.pointee.object, from, cb, MDKSeekFlag(flag.rawValue))
    }

    public func onStateChanged(callback:((State)->Void)?) -> Void {
        func f_(state:MDK_State, opaque:UnsafeMutableRawPointer?)->Void {
            let obj = Unmanaged<Player>.fromOpaque(opaque!).takeUnretainedValue()
            obj.state_cb_!(State(rawValue: state.rawValue)!)
        }
        state_cb_ = callback
        var cb = mdkStateChangedCallback()
        cb.cb = f_
        if callback != nil {
            cb.opaque = bridge(obj: self)!
        }
        player.pointee.onStateChanged(player.pointee.object, cb)
    }

    public func waitFor(_ state:State, timeout:Int? = -1) -> Bool {
        return player.pointee.waitFor(player.pointee.object, MDK_State(state.rawValue), timeout ?? -1)
    }

    public func onMediaStatusChanged(callback:((MediaStatus)->Bool)?) {
        func f_(status:MDK_MediaStatus, opaque:UnsafeMutableRawPointer?)->Bool {
            let obj = Unmanaged<Player>.fromOpaque(opaque!).takeUnretainedValue()
            return obj.status_cb_!(MediaStatus(rawValue: status.rawValue))
        }
        status_cb_ = callback
        var cb = mdkMediaStatusChangedCallback()
        cb.cb = f_
        if callback != nil {
            cb.opaque = bridge(obj: self)!
        }
        player.pointee.onMediaStatusChanged(player.pointee.object, cb)
    }

    public func setVideoSurfaceSize(_ width:Int32, _ height:Int32, vid:AnyObject? = nil) ->Void {
        player.pointee.setVideoSurfaceSize(player.pointee.object, width, height, bridge(obj: vid))
    }

    /*!
      \brief setVideoViewport
      The rectangular viewport where the scene will be drawn relative to surface viewport.
      x, y, width, height are normalized to [0, 1]
    */
    public func setVideoViewport(x:Float, y:Float, width:Float, height:Float, vid:AnyObject? = nil) ->Void {
        player.pointee.setVideoViewport(player.pointee.object, x, y, width, height, bridge(obj: vid))
    }

    public func setAspectRatio(_ value:Float, vid:AnyObject? = nil) ->Void {
        player.pointee.setAspectRatio(player.pointee.object, value, bridge(obj: vid))
    }

    public func mapPoint(_ dir:MapDirection, x:inout Float, y:inout Float, vid:AnyObject? = nil) -> Void {
        player.pointee.mapPoint(player.pointee.object, MDK_MapDirection(dir.rawValue), &x, &y, nil, bridge(obj: vid))
    }

    public func rotate(_ degree:Int32, vid:AnyObject? = nil) -> Void {
        player.pointee.rotate(player.pointee.object, degree, bridge(obj: vid))
    }

    public func scale(x:Float, y:Float, vid:AnyObject? = nil) -> Void {
        player.pointee.scale(player.pointee.object, x, y, bridge(obj: vid))
    }

    public func setBackgroundColor(red:Float, green:Float, blue:Float, alpha:Float, vid:AnyObject? = nil) -> Void {
        player.pointee.setBackgroundColor(player.pointee.object, red, green, blue, alpha, bridge(obj: vid))
    }

    public func set(effect:VideoEffect, values:[Float], vid:AnyObject? = nil) -> Void {
        player.pointee.setVideoEffect(player.pointee.object, MDK_VideoEffect(effect.rawValue), values, bridge(obj: vid))
    }

    public func set(colorSpace:ColorSpace, vid:AnyObject? = nil) -> Void {
        player.pointee.setColorSpace(player.pointee.object, MDK_ColorSpace(colorSpace.rawValue), bridge(obj: vid))
    }

    public func setRenderCallback(_ callback:(()->Void)?) -> Void {
        func f_(vo_opaque:UnsafeMutableRawPointer?, opaque:UnsafeMutableRawPointer?)->Void {
            let obj = Unmanaged<Player>.fromOpaque(opaque!).takeUnretainedValue()
            return obj.render_cb_!()
        }
        render_cb_ = callback
        var cb = mdkRenderCallback()
        cb.cb = f_
        if callback != nil {
            cb.opaque = bridge(obj: self)!
        }
        player.pointee.setRenderCallback(player.pointee.object, cb)
    }

    // TODO: onVideo, onAudio, beforeVideoRender, afterVideoRender

    public func seek(_ pos:Int64, flags:SeekFlag, callback:((Int64)->Void)?) -> Bool {
        typealias Callback = (Int64)->Void
        func f_(ms:Int64, opaque:UnsafeMutableRawPointer?)->Void {
            let obj = Unmanaged<Player>.fromOpaque(opaque!).takeUnretainedValue()
            return obj.seek_cb_!(ms)
        }
        seek_cb_ = callback
        var cb = mdkSeekCallback()
        cb.cb = f_
        if callback != nil {
            cb.opaque = bridge(obj: self)!
        }
        return player.pointee.seekWithFlags(player.pointee.object, pos, MDK_SeekFlag(rawValue: flags.rawValue), cb)
    }

    public func seek(_ pos:Int64, callback:((Int64)->Void)?) -> Bool {
        return seek(pos, flags: .Default, callback: callback)
    }

    public func buffered(bytes:inout Int64) -> Int64 {
        return player.pointee.buffered(player.pointee.object, &bytes)
    }

    public func buffered() -> Int64 {
        return player.pointee.buffered(player.pointee.object, nil)
    }

    public func setBufferRange(msMin:Int64 = -1, msMax:Int64 = -1, drop:Bool = false) -> Void {
        player.pointee.setBufferRange(player.pointee.object, msMin, msMax, drop)
    }

    public func swithBitrate(url:String, delay:Int64 = -1, callback:((Bool)->Void)?) -> Void {
        func f_(result:Bool, opaque:UnsafeMutableRawPointer?)->Void {
            let obj = Unmanaged<Player>.fromOpaque(opaque!).takeUnretainedValue()
            return obj.switch_cb_!(result)
        }
        switch_cb_ = callback
        var cb = SwitchBitrateCallback()
        cb.cb = f_
        if callback != nil {
            cb.opaque = bridge(obj: self)!
        }
        player.pointee.switchBitrate(player.pointee.object, url, delay, cb)
    }

    // TODO: onEvent

    public func record(to:String?, format:String?) -> Void {
        player.pointee.record(player.pointee.object, to, format)
    }
    /*
    func onLoop(<#parameters#>) -> <#return type#> {
        <#function body#>
    }*/

    public func setRange(from msA:Int64, to msB:Int64 = -1) -> Void {
        player.pointee.setRange(player.pointee.object, msA, msB)
    }

    public func setProperty(name:String, value:String) -> Void {
        player.pointee.setProperty(player.pointee.object, name, value)
    }

    /*public func property(name:String) -> String? {
        return player.pointee.getProperty(player.pointee.object, name)
    }*/

    public func onSync(_ callback:@escaping ()->Double, minInterval:Int32 = 10) -> Void {
        func f_(opaque:UnsafeMutableRawPointer?)->Double {
            let obj = Unmanaged<Player>.fromOpaque(opaque!).takeUnretainedValue()
            return obj.sync_cb_!()
        }
        sync_cb_ = callback
        var cb = mdkSyncCallback()
        cb.cb = f_
        cb.opaque = bridge(obj: self)!
        player.pointee.onSync(player.pointee.object, cb, minInterval)
    }

    // surface: UIView, NSView, CALayer
    public func updateNativeSurface(_ surface: AnyObject, width : Int32, height : Int32) {
        var ra = mdkMetalRenderAPI()
        ra.type = MDK_RenderAPI_Metal
        setRenderAPI(&ra, vid: surface)
        player.pointee.updateNativeSurface(player.pointee.object, bridge(obj: surface), width, height, MDK_SurfaceType(0));
    }

    // TODO: nil is all
    private func setActiveTracks(type:MediaType, tracks:[Int]) {
        tracks.withUnsafeBufferPointer({ [weak self] bp in
            guard let self = self else {return}
            self.player.pointee.setActiveTracks(self.player.pointee.object, MDK_MediaType(type.rawValue), UnsafePointer<Int32>(OpaquePointer(bp.baseAddress)), tracks.count)

        })
    }

    public init() {
        player = mdkPlayerAPI_new()
        owner_ = true
    }

    // Player(UnsafePointer<mdkPlayerAPI>(OpaquePointer(bitPattern: Int(handle))))
    public init(_ ptr: UnsafePointer<mdkPlayerAPI>!) {
        player = ptr
        owner_ = false
    }

    deinit {
        if (owner_) {
            mdkPlayerAPI_delete(&player)
        }
    }

    private var player : UnsafePointer<mdkPlayerAPI>!
    private var info = MediaInfo()
    private var owner_ = true

    private var prepare_cb_ : ((Int64, inout Bool)->Bool)?
    private var current_cb_ : (()->Void)?
    private var timeout_cb_ : ((Int64)->Bool)?
    private var state_cb_ : ((State)->Void)?
    private var status_cb_ : ((MediaStatus)->Bool)?
    private var render_cb_ : (()->Void)?
    private var seek_cb_ : ((Int64)->Void)?
    private var switch_cb_ : ((Bool)->Void)?
    private var sync_cb_ : (()->Double)?
}

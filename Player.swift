//
//  Player.swift
//  SwiftPlayer
//
//  Created by WangBin on 2020/12/1.
//

import mdk
import MetalKit
// https://stackoverflow.com/questions/43880839/swift-unable-to-cast-function-pointer-to-void-for-use-in-c-style-third-party
// https://stackoverflow.com/questions/37401959/how-can-i-get-the-memory-address-of-a-value-type-or-a-custom-struct-in-swift
// https://stackoverflow.com/questions/33294620/how-to-cast-self-to-unsafemutablepointervoid-type-in-swift
import Foundation // needed for strdup and free

public enum MediaType : Int32 {
    case Unknown = -1
    case Video = 0
    case Audio = 1
    case Subtitle = 2
}
// TODO: RawOptionSet?
public enum MediaStatus : UInt32 {
    case NoMedia = 0
    case Unloaded = 1
    case Loading = 2
    case Loaded = 4
    case Prepared = 256
    case Stalled = 8
    case Buffering = 16
    case Buffered = 32
    case End = 64
    case Seeking = 128
    case Invalid = 0xffffffff
}

public enum State : UInt32 {
    case Stopped = 0
    case Playing = 1
    case Paused = 2
}

public enum SeekFlag : UInt32 {
    case From0 = 1
    case FromStart = 2
    case FromNow = 4
    case KeyFrame = 256
    case Default = 257
}

public enum VideoEffect : UInt32 {
    case Brightness = 0
    case Contrast = 1
    case Hue = 2
    case Saturation = 3
}

public enum LogLevel : UInt32 {
    case Off = 0
    case Error = 1
    case Warning = 2
    case Info = 3
    case Debug = 4
    case All = 5
}

public func version() ->Int32 {
    return MDK_version()
}

public func setLogLevel(_ value : LogLevel) {
    MDK_setLogLevel(MDK_LogLevel(value.rawValue))
}

public func logLevel() ->LogLevel {
    return LogLevel(rawValue: MDK_logLevel().rawValue)!
}

public typealias LogHandler = (LogLevel,String)->Void
public func setLogHandler(_ callback:LogHandler?) {
    struct H {
        static var cb : UnsafeMutableRawPointer? //LogHandler?
    }
    if H.cb == nil {
        H.cb = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<LogHandler>.stride, alignment: MemoryLayout<LogHandler>.alignment)
    }
    var tmp = callback
    H.cb?.initializeMemory(as: LogHandler.self, from: &tmp!, count: 1)
    func _f(level : MDK_LogLevel, msg : UnsafePointer<CChar>?, opaque : UnsafeMutableRawPointer?) {
        let f = opaque?.load(as: LogHandler.self)
        f!(LogLevel(rawValue: level.rawValue)!, String(cString: msg!))
    }
    var h = mdkLogHandler()
    if callback == nil {
        h.opaque = nil
    } else {
        h.opaque = H.cb
    }
    h.cb = _f
    MDK_setLogHandler(h)
    // TODO: reset before H.cb destroyed
}

public func setGlobalOption<T>(name:String, value:T) {
    //var ptr = UnsafePointer(&s.utf8CString)
    if T.self == String.self {
        (value as! String).withCString({
            MDK_setGlobalOptionString(name, $0)
        })
    } else if T.self == Int32.self {
        MDK_setGlobalOptionInt32(name, value as! Int32)
    } else if T.self == Bool.self {
        let v = Int32(value as! Bool ? 1 : 0)
        MDK_setGlobalOptionInt32(name, v)
    } else if T.self == Int.self {
        let v = Int32(value as! Int)
        MDK_setGlobalOptionInt32(name, v)
    }
}

func declmetatype<T>(_: T) -> T.Type {
    return T.self
}
// for char const* []
func withArrayOfCStrings2<R>(
    _ args: [String],
    _ body: ([OpaquePointer?]) -> R
) -> R {
    var cStrings = args.map { OpaquePointer(strdup($0)) }
    cStrings.append(nil)
    defer {
        cStrings.forEach { free(UnsafeMutablePointer<CChar>($0)) }
    }
    return body(cStrings)
}

// for char* const []
func withArrayOfCStrings<R>(
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


func bridge<T : AnyObject>(obj : T) -> UnsafeRawPointer {
    return UnsafeRawPointer(Unmanaged.passUnretained(obj).toOpaque())
    // return unsafeAddressOf(obj) // ***
}

func bridge<T : AnyObject>(obj : T) -> UnsafeMutableRawPointer {
    return UnsafeMutableRawPointer(Unmanaged.passUnretained(obj).toOpaque())
    // return unsafeAddressOf(obj) // ***
}

func bridge<T : AnyObject>(ptr : UnsafeRawPointer) -> T {
    return Unmanaged<T>.fromOpaque(ptr).takeUnretainedValue()
    // return unsafeBitCast(ptr, T.self) // ***
}

func address(o: UnsafeRawPointer) -> OpaquePointer {
    return unsafeBitCast(o, to: OpaquePointer.self)
}

class Player {
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
                $0.withUnsafeBufferPointer({
                    let ptr = UnsafeMutablePointer<UnsafePointer<Int8>?>(OpaquePointer($0.baseAddress))
                    player.pointee.setAudioDecoders(player.pointee.object, ptr)
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
                    player.pointee.setVideoDecoders(player.pointee.object, ptr)
                })
            }
        }
    }
    
    public var state:State = .Stopped {
        didSet {
            player.pointee.setState(player.pointee.object, MDK_State(state.rawValue))
        }
    }
    
    public var mediaStatus : MDK_MediaStatus {
        get {
            return player.pointee.mediaStatus(player.pointee.object)
        }
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
        
    private var player : UnsafePointer<mdkPlayerAPI>! = mdkPlayerAPI_new()
   
    deinit {
        mdkPlayerAPI_delete(&player)
        // TODO: deallocate callbacks?
    }

    public func setRendAPI(_ api :  UnsafePointer<mdkMetalRenderAPI>) ->Void {
        player.pointee.setRenderAPI(player.pointee.object, OpaquePointer(api), nil)
    }

    // TODO: UIView, NSView, GLKView
    public func setRenderTarget(_ mkv : MTKView, commandQueue cmdQueue: MTLCommandQueue) ->Void {
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
        setRendAPI(&ra)
    }

    public func setVideoSurfaceSize(_ width : CGFloat, _ height : CGFloat)->Void {
        player.pointee.setVideoSurfaceSize(player.pointee.object, Int32(width), Int32(height), nil)
    }

    public func renderVideo() -> Double {
        return player.pointee.renderVideo(player.pointee.object, nil)
    }
    
    public func set(media:String, forType type:MediaType) {
        player.pointee.setMediaForType(player.pointee.object, media, MDK_MediaType(type.rawValue))
    }
    
    public func setNext(media:String, from:Int64 = 0, withSeekFlag flag:SeekFlag = .Default) {
        player.pointee.setNextMedia(player.pointee.object, media, from, MDKSeekFlag(flag.rawValue))
    }
    
    public func currentMediaChanged(_ callback:(()->Void)?) {
        func f_(opaque:UnsafeMutableRawPointer?) {
            let f = opaque?.load(as: (()->Void).self)
            f!()
        }
        var cb = mdkCurrentMediaChangedCallback()
        cb.cb = f_
        if callback != nil {
            if current_cb_ == nil {
                current_cb_ = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<()>.stride, alignment: MemoryLayout<()>.alignment)
            }
            cb.opaque = current_cb_
            var tmp = callback
            cb.opaque.initializeMemory(as: type(of: callback), from: &tmp, count: 1)
        }
        player.pointee.currentMediaChanged(player.pointee.object, cb)
    }
    
    public func setTimeout(_ value:Int64, callback:((Int64)->Bool)?) -> Void {
        typealias Callback = (Int64)->Bool
        func f_(value:Int64, opaque:UnsafeMutableRawPointer?)->Bool {
            let f = opaque?.load(as: Callback.self)
            return f!(value)
        }
        var cb = mdkTimeoutCallback()
        cb.cb = f_
        if callback != nil {
            if timeout_cb_ == nil {
                timeout_cb_ = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Callback>.stride, alignment: MemoryLayout<Callback>.alignment)
            }
            cb.opaque = timeout_cb_
            var tmp = callback
            cb.opaque.initializeMemory(as: type(of: callback), from: &tmp, count: 1)
        }
        player.pointee.setTimeout(player.pointee.object, value, cb)
    }
    
    public func prepare(from:Int64, complete:((Int64, inout Bool)->Bool)?, _ flag:SeekFlag = .Default) {
        typealias Callback = (Int64, inout Bool)->Bool
        func _f(pos:Int64, boost:UnsafeMutablePointer<Bool>?, opaque:UnsafeMutableRawPointer?)->Bool {
            let f = opaque?.load(as: (Callback).self)
            var _boost = true
            let ret = f!(pos, &_boost)
            boost?.assign(from: &_boost, count: 1)
            return ret
        }
        var cb = mdkPrepareCallback()
        if complete != nil {
            if prepare_cb == nil {
                prepare_cb = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Callback>.stride, alignment: MemoryLayout<Callback>.alignment)
            }
            //cb.opaque = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<(Int64, inout Bool)->Bool>.stride, alignment: MemoryLayout<(Int64, inout Bool)->Bool>.alignment)
            cb.opaque = prepare_cb
            var tmp = complete
            cb.opaque.initializeMemory(as: type(of: complete), from: &tmp, count: 1)
        }
        cb.cb = _f
        player.pointee.prepare(player.pointee.object, from, cb, MDKSeekFlag(flag.rawValue))
    }
    
    public func onStateChanged(callback:((State)->Void)?) -> Void {
        typealias Callback = (State)->Void
        func f_(state:MDK_State, opaque:UnsafeMutableRawPointer?)->Void {
            let f = opaque?.load(as: Callback.self)
            f!(State(rawValue: state.rawValue)!)
        }
        var cb = mdkStateChangedCallback()
        cb.cb = f_
        if callback != nil {
            if state_cb_ == nil {
                state_cb_ = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Callback>.stride, alignment: MemoryLayout<Callback>.alignment)
            }
            cb.opaque = state_cb_
            var tmp = callback
            cb.opaque.initializeMemory(as: type(of: callback), from: &tmp, count: 1)
        }
        player.pointee.onStateChanged(player.pointee.object, cb)
    }
    
    public func waitFor(_ state:State, timeout:Int) -> Bool {
        return player.pointee.waitFor(player.pointee.object, MDK_State(state.rawValue), timeout)
    }
    
    public func onMediaStatusChanged(callback:((MDK_MediaStatus)->Bool)?) {
        typealias Callback = (MDK_MediaStatus)->Bool
        func f_(status:MDK_MediaStatus, opaque:UnsafeMutableRawPointer?)->Bool {
            let f = opaque?.load(as: Callback.self)
            return f!(status)
        }
        var cb = mdkMediaStatusChangedCallback()
        cb.cb = f_
        if callback != nil {
            if status_cb_ == nil {
                status_cb_ = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Callback>.stride, alignment: MemoryLayout<Callback>.alignment)
            }
            cb.opaque = status_cb_
            var tmp = callback
            cb.opaque.initializeMemory(as: type(of: callback), from: &tmp, count: 1)
        }
        player.pointee.onMediaStatusChanged(player.pointee.object, cb)
    }
    
    private var prepare_cb : UnsafeMutableRawPointer? //((Int64, inout Bool)->Bool)?
    private var current_cb_ : UnsafeMutableRawPointer? // ()->Void
    private var timeout_cb_ : UnsafeMutableRawPointer? // (Int64)->Bool
    private var state_cb_ : UnsafeMutableRawPointer? // (State)->Void
    private var status_cb_ : UnsafeMutableRawPointer? // (MDK_MediaStatus)->Bool
}

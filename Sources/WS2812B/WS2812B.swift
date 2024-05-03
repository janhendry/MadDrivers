import SwiftIO

// The WS2812B class is used to control WS2812B LED strips.
final public class WS2812B {
    private var pinOut: DigitalOut
    private var pixelType: PixelType
    private var lastPullDownTime: UInt64
    
    init(pinId: IdName, pixelType: PixelType = .rgb) {
        self.pixelType = pixelType
        self.pinOut = DigitalOut(pinOut, .pushPull, false)
        self.lastPullDownTime = getClockCycle()
    }
    
    func sendPixel(_ pixelArray: [PixelColor]) {
        while (cyclesToNanoseconds(lastPullDownTime, getClockCycle()) < 300000) {
            // wait for REST signal
        }
      
        for pixel in pixelArray {
            sendPixel(pixel)
        }

        lastPullDownTime = getClockCycle()
    }
    
    // send a single pixel to the WS2812B LED strip
    private func sendPixelFrame(_ pixel: PixelColor) {
        let frame = getPixelFrame(pixel)
        
        for byte in frame {
            for i in (0..<8).reversed() {
                if (byte & (1 << i)) != 0 {
                    sendBitOne()
                } else {
                    sendBitZero()
                }
            }
        }
    }

    // Send a single bit '1'
    private func sendBitOne() {
        pin.write(value: true)
        sleep(700)
        pin.write(value: false)
        sleep(600)
    }

    // Send a single bit '0'
    private func sendBitZero() {
        pin.write(value: true)
        sleep(350)
        pin.write(value: false)
        sleep(800)
    }

    private getPixelFrame(_ pixel: PixelColor) -> [UInt8] {
        
        switch pixelType {
            case .rgb:
                return [pixel.red, pixel.green, pixel.blue]
            case .grb:
                return [pixel.green, pixel.red, pixel.blue]
            case .rgbw:
                return [pixel.red, pixel.green, pixel.blue, pixel.white]
            case .grbw:
                return [pixel.green, pixel.red, pixel.blue, pixel.white]
        }
    }

    public struct PixelColor {
        var red: UInt8
        var green: UInt8
        var blue: UInt8
        var white: UInt8?
    }

    // The PixelType enum is used to specify the order of the color channels in the pixel frame.
    public enum PixelType {
        case rgb
        case grb
        case rgbw
        case grbw
    }
}

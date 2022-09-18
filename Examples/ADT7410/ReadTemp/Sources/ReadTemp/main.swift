import SwiftIO
import MadBoard
import ADT7410


let i2c = I2C(Id.I2C1)
let sensor = ADT7410(i2c)

while (true) {
    sleep(ms: 2000)
//    print("Tempature is \(sensor.readCelcius()) C")
    
    var buffer: [UInt8] = []
    i2c.writeRead(0x00, into: &buffer, readCount: 1, address:  0x48)
    print(buffer)
}

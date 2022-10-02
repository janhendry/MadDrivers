import MAX6675
import SwiftIO
import MadBoard

print("Read tempature with Max6675 sensor.")

let csPin = DigitalOut(Id.D17)
let spi = SPI(Id.SPI1,csPin: csPin)
let max6675 = MAX6675(spi: spi)

while true {
    sleep(ms: 2000)
    print("Temparture is \(max6675.readCelsius()).")
}


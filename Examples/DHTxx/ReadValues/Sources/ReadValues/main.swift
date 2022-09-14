// Read temperature every 2 seconds.
import SwiftIO
import SwiftIOBoard


let spiId       = Id.SPI1

let sckId: Id   = Id.D14
let csId: Id    = Id.D17
let soId: Id    = Id.D16
let speed = 1_000

//let spi = SPIPin(sck: DigitalOut(sckId), cs: DigitalOut(csId), so: DigitalIn(soId))
let spi = SPI(spiId,csPin: DigitalOut(csId))
let max6675 = MAX6675(spi: spi)


while(true){
    sleep(ms: 2_000)
    print(max6675.readCelsius() ?? "fail")
}

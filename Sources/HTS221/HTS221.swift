//=== TSL2591.swift -------------------------------------------------------===//
//
// Copyright (c) MadMachine Limited
// Licensed under MIT License
//
// Authors: Jan Anstipp
// Created: 09/23/2022
//
// See https://madmachine.io for more information
//
//===----------------------------------------------------------------------===//

import SwiftIO
import CoreFoundation

public class HTS221 {
    private let i2c: I2C
    private let serialBusAddress: UInt8 = 0b10111110
    lazy private var configuration: Configuration = Configuration()//vreadConfig()
    
    private var humiditySlope: Double = 0
    private var humidityZero: Double = 0
    private var temperatureSlope: Double = 0
    private var temperatureZero: Double = 0
    
    init(ic2: I2C) {
        self.i2c = ic2
        calibratSensor()
    }
    
    func readCelcius() -> Double{
        /// Check is update data rate == one shot
        if (read(.CTRL_REG1) & 0b11) > 0 {
            write([read(.CTRL_REG2) | 1], to: .CTRL_REG2)
            while (read(.CTRL_REG2) & 1 ) > 0 {
                wait(us: 10)
            }
        }
        
        let tOut = read(.TEMP_OUT_L)
        return (Double(tOut) * temperatureSlope + temperatureZero);
    }
    
    func readHumidity(){
        
    }
    
    
    enum RegisterAddress: UInt8 {
        case WHO_AM_I = 0x0F /// Device identification 10111100
        case AV_CONF = 0x10 /// Humidity and temperature resolution mode
        case CTRL_REG1 = 0x20
        case CTRL_REG2 = 0x21
        case CTRL_REG3 = 0x22
        case STATUS_REG = 0x27
        case HUMIDITY_OUT_L = 0x28
        case HUMIDITY_OUT_H = 0x29
        case TEMP_OUT_L = 0x2A
        case TEMP_OUT_H  = 0x2B
    }
    
    enum CalibrationRegisterAddres: UInt8{
        case H0_rH = 0x30
        case H1_rH = 0x31
        case T0_degC = 0x32
        case T1_degC = 0x33
        case T1_T0_msb = 0x34
        case H0_T0_OUT = 0x35
        case H1_T0_OUT = 0x3A
        case T0_OUT = 0x3C
        case T1_OUT = 0x3E
    }
    
    /// The number of averaged temperature samples.
    enum TempNumberSamples: UInt8{
        case _2 = 0b000000
        case _4 = 0b001000
        case _8 = 0b010000
        case _16 = 0b011000
        case _32 = 0b100000
        case _64 = 0b101000
        case _128 = 0b110000
        case _256 = 0b111000
    }

    /// The PowerMode is used to turn on/off the device. The device is default off after boot.
    enum PowerMode: UInt8{
        case ON = 0b10000000
        case OFF = 0b0
    }
    
    /// The block data update bit is used to inhibit the output register update between the reading of the upper and lower register parts. In default mode (BDU = ‘0’), the lower and upper register parts are updated continuously. If it is not certain whether the read will be faster than output data rate, it is recommended to set the BDU bit to ‘1’. In this way, after the reading of the lower (upper) register part, the content of that output register is not updated until the upper (lower) part is read also.
    enum BlockDataUpdate: UInt8{
        case updatedContinuously = 0
        case blockUpdatedByReading = 0b100
    }
    
    /// Update data rates of humidity and temperature samples. Default is “one-shot”.
    enum UpdateDataRate: UInt8{
        case OneShot = 0
        case _1Hz = 1
        case _7Hz = 2
        case _12_5Hz = 3
    }
    
    /// BootState describes whether the chip is currently booting or not.
    enum BootState: UInt8{
        case running = 0
        case booting = 0b10000000
    }
    
    /// The DRDY_EN bit enables the DRDY signal on pin 3. Normally inactive, the DRDY output signal becomes active on new data available: logical OR of the bits STATUS_REG[1] and STATUS_REG[0] for humidity and temperature, respectively. The DRDY signal returns inactive after both HUMIDITY_OUT_H and TEMP_OUT_H registers are read.
    enum DRDY_EN: UInt8{
        case inactive = 0
        case active = 0b100
    }
    
    /// Humidity data available. . H_DA is cleared anytime HUMIDITY_OUT_H register is read.
    enum H_DA: UInt8{
        case notAvailable = 0 // new data for humidity is not yet available
        case available = 0b10 // new data for humidity is available)
    }
    
    /// Temperature data available. . T_DA is cleared anytime TEMP_OUT_H register is read.
    enum T_DA: UInt8{
        case notAvailable = 0 // new data for temperature is not yet available
        case available = 1 // new data for temperature is available
    }
    
    /// When the chip is booted, the contents of the internal flash are copied to the appropriate internal registers and used to calibrate the instrument. If for some reason the contents of the trim registers are changed, a reboot of the chip is sufficient to restore the correct values. At the end of the boot process, the BOOT bit is set back to '0'.
    func reboot() {
        write([read(.CTRL_REG2) | 1<<7], to: .CTRL_REG2)
    }
    
    func isBooting() -> Bool{
        read(.CTRL_REG2).isBitSet(7)
    }
    
    /// State of the internal heating element. The heating element can be used to speed up the sensor recovery time in case of condensation. Humidity and temperature output should not be read during the heating cycle; valid data can be read out once the heater has been turned off, after the completion of the heating cycle.
    func isHeating() -> Bool{
        read(.CTRL_REG2).isBitSet(1)
    }
    
    func enableHeater(){
        write([read(.CTRL_REG2) | 1<<1], to: .CTRL_REG2)
    }
    
    func disableHeater() {
        write([read(.CTRL_REG2) & 0b11111101], to: .CTRL_REG2)
    }
    
    func readCalibration () -> CalibrationValue{
        let calibartion = CalibrationValue()
        calibartion.h0rH = read(.H0_rH)
        calibartion.h1rH = read(.H1_rH)
        calibartion.t0degC = read(.T0_degC)
        calibartion.t1degC = read(.T1_degC)
        calibartion.t0t1msb = read(.T1_T0_msb)
        calibartion.h0t0out = read(.H0_T0_OUT)
        calibartion.h1t0out = read(.H1_T0_OUT)
        calibartion.t0out = read(.T0_OUT)
        calibartion.t1out = read(.T1_OUT)
        return calibartion
    }
    
    func calibratSensor(){
        let cV = readCalibration()
        let t0degC: Int16 = (cV.t0t1msb.toInt16() & 0x3) << 8 | cV.t0degC.toInt16()
        let t1degC: Int16 = (cV.t0t1msb.toInt16() & 0xc) << 6 | cV.t1degC.toInt16()
   
        humiditySlope = Double((cV.h1rH - cV.h0rH)) / (2.0 * Double(( cV.h1t0out - cV.h0t0out)))
        humidityZero = (Double(cV.h0rH) / 2.0) - humiditySlope * Double(cV.h0t0out)

        temperatureSlope = Double((t1degC - t0degC)) / (8.0 * Double(cV.t1out - cV.t0out))
        temperatureZero = Double(t0degC) / 8.0 - temperatureSlope * Double(cV.t0out)
    }
}

extension HTS221 {
    
    func read(_ registerAddresse: RegisterAddress) -> UInt8{
        read(registerAddresse.rawValue, 1)[0]
    }
  
    func read(_ registerAddresse: CalibrationRegisterAddress) -> UInt8{
        read(registerAddresse.rawValue, 1)[0]
    }
    
    func read(_ registerAddresse: CalibrationRegisterAddress) -> Int16{
        let data = read(registerAddresse.rawValue, 2)
        return data[1].toInt16() << 8 | data[0].toInt16()
    }
    
    func read(_ registerAddresse: UInt8,_ registerSize: Int) -> [UInt8]{
        var buffer: [UInt8] = [UInt8](repeating: 0, count: registerSize)
        i2c.writeRead(registerAddresse, into: &buffer, address: serialBusAddress)
        return buffer
    }
    
    func write(_ data: [UInt8],to registerAddresse: RegisterAddress) {
        i2c.write([registerAddresse.rawValue]+data, to: serialBusAddress)
    }

}

extension UInt8{
    func isBitSet(_ index: Int) -> Bool{
        (self & (1 << index)) != 0
    }
    
    func toInt16() -> Int16{
        Int16(bitPattern: UInt16(self))
    }
}

enum CalibrationRegisterAddress: UInt8{
    case H0_rH = 0x30
    case H1_rH = 0x31
    case T0_degC = 0x32
    case T1_degC = 0x33
    case T1_T0_msb = 0x34
    case H0_T0_OUT = 0x35
    case H1_T0_OUT = 0x3A
    case T0_OUT = 0x3C
    case T1_OUT = 0x3E
}


class CalibrationValue{
    var h0rH: UInt8 = 0
    var h1rH: UInt8 = 0
    var t0degC: UInt8 = 0
    var t1degC: UInt8 = 0
    var t0t1msb: UInt8 = 0
    var h0t0out: Int16 = 0
    var h1t0out: Int16 = 0
    var t0out: Int16 = 0
    var t1out: Int16 = 0
    
    init(){}
}


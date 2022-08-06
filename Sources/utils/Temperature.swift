//=== Temperature.swift --------------------------------------------------------===//
//
// Copyright (c) MadMachine Limited
// Licensed under MIT License
//
// Authors: Jan Anstipp
// Created: 06/16/2022
//
// See https://madmachine.io for more information
//
//===----------------------------------------------------------------------===//


struct Temperature{

    /**
     Celsius to Kelvin conversion:
     K = C + 273.15
     @param celsius - temperature in degree Celsius to convert
     @return temperature in degree Kelvin
     */
    public static func toKelvins(celsius:Double) -> Double {
        celsius + 273.15
    }

    /**
     Celsius to Fahrenheit conversion:
     F = C * 1.8 + 32
     @param celsius - temperature in degree Celsius to convert
     @return temperature in degree Fahrenheit
     */
    public static func toFahrenheit(celsius:Double) -> Double{
        celsius * 1.8 + 32
    }
}


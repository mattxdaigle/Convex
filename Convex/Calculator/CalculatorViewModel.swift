//
//  CalculatorViewModel.swift
//  Convex
//
//  Created by Matt Daigle on 7/1/24.
//

import Combine
import SwiftUI

extension CalculatorView {

    @Observable
    final class ViewModel: ObservableObject {

        // MARK: - Properties

        private var model = CalculatorModel()

        private var currentValue: UInt = 0 {
            didSet {
                updateDisplayValue()
            }
        }
        var displayValue: String = "0x0"
        var selectedBase: Base = .hex {
            didSet {
                updateDisplayValue()
            }
        }

        var bases: [Base] {
            model.bases
        }

        var operations: [Operation] {
            model.operations
        }

        var numbersRowCount: Int {
            model.numbers.count
        }

        var numbersColumnCount: Int {
            model.numbers.first?.count ?? 0
        }

        private var pasteboardValue: UInt? {
            guard let pasteboardString = UIPasteboard.general.string, let base = Base(string: pasteboardString) else {
                return nil
            }

            return UInt(pasteboardString.trimmingPrefix(base.prefix), radix: base.radix)
        }

        private(set) var canPaste = false

        private var cancellables = Set<AnyCancellable>()

        // MARK: - Initializers

        init() {
            NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)
                .sink { [weak self] _ in
                    guard let self else { return }
                    self.canPaste = self.pasteboardValue != nil
                }
                .store(in: &cancellables)
        }

        // MARK: - UI Interpretation

        func isDecimal(value: UInt) -> Bool {
            Base.decimal.values.contains(value)
        }

        func isValueEnabled(_ value: UInt) -> Bool {
            selectedBase.values.contains(value)
        }

        func numberFor(row: Int, column: Int) -> UInt? {
            guard row < model.numbers.count, column < model.numbers[row].count else {
                return nil
            }

            return model.numbers[row][column]
        }

        func append(_ digit: UInt) {
            currentValue = model.append(digit, to: currentValue, radix: selectedBase.radix)
        }

        func backspace() {
            currentValue = model.removeLeastSignificantDigit(from: currentValue, radix: selectedBase.radix)
        }

        func copy() {
            UIPasteboard.general.string = selectedBase.prefix + String(currentValue, radix: selectedBase.radix)
        }

        func paste() {
            if let pasteboardValue {
                currentValue = pasteboardValue
            }
        }

        func clear() {
            currentValue = 0
        }

        func perform(_ operation: Operation) {
            currentValue = model.perform(operation, on: currentValue)
        }

        func updateDisplayValue() {
            switch selectedBase {
            case .binary:
                // Convert to binary and pad with zeroes.
                let binaryString = String(currentValue, radix: 2)
                let cpuRegisterSize = String(UInt.max, radix: 2).count
                let zeroPadding = (0..<cpuRegisterSize - binaryString.count).map { _ in "0" }
                let paddedBinaryString = zeroPadding.joined() + binaryString
                let groupSize = 4

                let formattedString: String
                if cpuRegisterSize == 32 {
                    formattedString = paddedBinaryString.groupedBy(groupSize)
                } else {
                    // Split the bits in half.
                    let midpoint = paddedBinaryString.index(paddedBinaryString.startIndex, offsetBy: paddedBinaryString.count/2)
                    let upperString = String(paddedBinaryString[paddedBinaryString.startIndex..<midpoint])
                    let lowerString = String(paddedBinaryString[midpoint..<paddedBinaryString.endIndex])
                    formattedString = upperString.groupedBy(groupSize) + "\n" + lowerString.groupedBy(groupSize)
                }

                displayValue = formattedString
            case .octal:
                displayValue = selectedBase.prefix + String(currentValue, radix: selectedBase.radix)
            case .decimal:
                let noCommaString = String(currentValue, radix: selectedBase.radix)
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal

                displayValue = formatter.string(from: NSNumber(value: currentValue)) ?? noCommaString
            case .hex:
                displayValue = selectedBase.prefix + String(currentValue, radix: selectedBase.radix, uppercase: true)
            }
        }
    }
}

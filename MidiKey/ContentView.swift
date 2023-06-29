import SwiftUI
import CoreMIDI
import Carbon

// MIDI to keyboard mapping
let shiftMod: UInt16 = 56
let midiToKeyboard: [UInt8: UInt16] = [
    36: 18,              // C2 -> 1
    37: 18,   // C#2 -> !
    38: 19,              // D2 -> 2
    39: 19,   // D#2 -> @
    40: 20,              // E2 -> 3
    41: 21,              // F2 -> 4
    42: 21,   // F#2 -> $
    43: 23,              // G2 -> 5
    44: 23,   // G#2 -> %
    45: 22,              // A2 -> 6
    46: 22,   // A#2 -> ^
    47: 26,              // B2 -> 7
    48: 28,              // C3 -> 8
    49: 28,   // C#3 -> *
    50: 25,              // D3 -> 9
    51: 25,   // D#3 -> (
    52: 29,              // E3 -> 0
    53: 12,              // F3 -> q
    54: 12,   // F#3 -> Q
    55: 13,              // G3 -> w
    56: 13,   // G#3 -> W
    57: 14,              // A3 -> e
    58: 14,   // A#3 -> E
    59: 15,              // B3 -> r
    60: 17,              // C4 -> t
    61: 17,   // C#4 -> T
    62: 16,              // D4 -> y
    63: 16,   // D#4 -> Y
    64: 32,              // E4 -> u
    65: 34,              // F4 -> i
    66: 34,   // F#4 -> I
    67: 31,              // G4 -> o
    68: 31,   // G#4 -> O
    69: 35,              // A4 -> p
    70: 35,   // A#4 -> P
    71: 0,               // B4 -> a
    72: 1,               // C5 -> s
    73: 1,    // C#5 -> S
    74: 2,               // D5 -> d
    75: 2,    // D#5 -> D
    76: 3,               // E5 -> f
    77: 5,               // F5 -> g
    78: 5,    // F#5 -> G
    79: 4,               // G5 -> h
    80: 4,    // G#5 -> H
    81: 38,              // A5 -> j
    82: 38,   // A#5 -> J
    83: 40,              // B5 -> k
    84: 37,              // C6 -> l
    85: 37,   // C#6 -> L
    86: 6,               // D6 -> z
    87: 6,    // D#6 -> Z
    88: 7,               // E6 -> x
    89: 8,               // F6 -> c
    90: 8,    // F#6 -> C
    91: 9,               // G6 -> v
    92: 9,    // G#6 -> V
    93: 11,              // A6 -> b
    94: 11,   // A#6 -> B
    95: 45,              // b -> n
    96: 46               // b -> m
]

var noteStates: [UInt8: Bool] = [:]
var midiClient: MIDIClientRef = 0
var inputPort: MIDIPortRef = 0

struct ContentView: View {
    @State private var isRunning = false

    var body: some View {
        VStack {
            Text("MidiKey")
                .font(.largeTitle)
                .padding(.bottom, 0) // Add padding at the bottom of the title
            Text("v0.1")
                .padding(.bottom, 5) // Add more padding at the bottom of the URL
            Text("github.com/esfied")
                .padding(.bottom, 25) // Add more padding at the bottom of the URL
            
            Button(action: {
                toggleMIDI()
            }) {
                Text(isRunning ? "STOP" : "START")
                    .font(Font.system(size: 12))
                    .padding()
                    .foregroundColor(.white)
            }
        }
        .frame(width: 300, height: 200)
    }

    func toggleMIDI() {
        if isRunning {
            stopMIDI()
        } else {
            startMIDI()
        }

        isRunning.toggle()
    }

    func startMIDI() {
        MIDIClientCreateWithBlock("MIDIClient" as CFString, &midiClient) { (notificationPtr: UnsafePointer<MIDINotification>) in
            // MIDI client notification if needed
        }

        MIDIInputPortCreateWithBlock(midiClient, "InputPort" as CFString, &inputPort) { (packetList: UnsafePointer<MIDIPacketList>, srcConnRefCon: UnsafeMutableRawPointer?) in
            if isRunning {
                handleMIDIEvent(packetList: packetList, readProcRefCon: srcConnRefCon)
            }
        }

        MIDIPortConnectSource(inputPort, MIDIGetSource(0), nil)
    }

    func stopMIDI() {
        noteStates.removeAll()

        // Release all keys
        for (_, keyCode) in midiToKeyboard {
            let keyEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
            keyEvent?.post(tap: .cghidEventTap)
        }
    }

    func handleMIDIEvent(packetList: UnsafePointer<MIDIPacketList>, readProcRefCon: UnsafeMutableRawPointer?) {
        let packets = packetList.pointee
        let packet = packets.packet
        
        var packetCursor = packet
        for _ in 0 ..< packets.numPackets {
            let _: UInt8 = packetCursor.data.0 // Excluding midiStatus
            let midiData1 = packetCursor.data.1
            let midiVelocity = packetCursor.data.2
            
            if midiVelocity > 0 {
                if let keyCode = midiToKeyboard[midiData1], !noteStates[midiData1, default: false] {
                    noteStates[midiData1] = true
                    
                    let shiftModifier = (midiData1 == 37 || midiData1 == 39 || midiData1 == 42 || midiData1 == 44 || midiData1 == 46 || midiData1 == 49 || midiData1 == 51 || midiData1 == 54 || midiData1 == 56 || midiData1 == 58 || midiData1 == 61 || midiData1 == 63 || midiData1 == 66 || midiData1 == 68 || midiData1 == 70 || midiData1 == 73 || midiData1 == 75 || midiData1 == 78 || midiData1 == 80 || midiData1 == 82 || midiData1 == 85 || midiData1 == 87 || midiData1 == 90 || midiData1 == 92 || midiData1 == 94)
                    
                    // Press the shift key
                    if shiftModifier {
                        let shiftDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: shiftMod, keyDown: true)
                        shiftDownEvent?.post(tap: .cghidEventTap)
                    }
                    
                    // Press the key
                    let keyEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
                    keyEvent?.post(tap: .cghidEventTap)
                    
                    // Release the key
                    let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
                    keyUpEvent?.post(tap: .cghidEventTap)
                    
                    // Release the shift key
                    if shiftModifier {
                        let shiftUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: shiftMod, keyDown: false)
                        shiftUpEvent?.post(tap: .cghidEventTap)
                    }
                }
            } else {
                if let keyCode = midiToKeyboard[midiData1] {
                    noteStates[midiData1] = false
                    
                    // Release the key
                    let keyEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
                    keyEvent?.post(tap: .cghidEventTap)
                }
            }
            
            packetCursor = MIDIPacketNext(&packetCursor).pointee
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

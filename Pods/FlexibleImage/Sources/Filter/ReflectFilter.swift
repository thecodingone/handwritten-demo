//
//  ReflectFilter.swift
//  Test Project
//
//  Created by Kawoou on 2017. 5. 12..
//  Copyright © 2017년 test. All rights reserved.
//

#if !os(watchOS)
    import Metal
#endif

internal class ReflectFilter: ImageFilter {
    
    // MARK: - Property
    
    internal override var metalName: String {
        get {
            return "ReflectFilter"
        }
    }
    
    internal var color: ColorType = (1.0, 1.0, 1.0, 1.0)
    
    
    // MARK: - Internal
    
    #if !os(watchOS)
        @available(OSX 10.11, iOS 8, tvOS 9, *)
        internal override func processMetal(_ device: ImageMetalDevice, _ commandBuffer: MTLCommandBuffer, _ commandEncoder: MTLComputeCommandEncoder) -> Bool {
            let factors: [Float] = [color.r, color.g, color.b, color.a]
            
            for i in 0..<factors.count {
                var factor = factors[i]
                let size = max(MemoryLayout<Float>.size, 16)
                
                let options: MTLResourceOptions
                if #available(iOS 9.0, *) {
                    options = [.storageModeShared]
                } else {
                    options = [.cpuCacheModeWriteCombined]
                }
                
                let buffer = device.device.makeBuffer(
                    bytes: &factor,
                    length: size,
                    options: options
                )
                commandEncoder.setBuffer(buffer, offset: 0, index: i)
            }
            
            return super.processMetal(device, commandBuffer, commandEncoder)
        }
    #endif
    
    override func processNone(_ device: ImageNoneDevice) -> Bool {
        let memoryPool = device.memoryPool!
        let width = Int(device.drawRect!.width)
        let height = Int(device.drawRect!.height)
        
        func reflect(_ a: UInt16, _ b: UInt16) -> UInt8 {
            if b == 255 {
                return UInt8(b)
            } else {
                return UInt8(min(255, a * a / (255 - b)))
            }
        }
        
        var index = 0
        for _ in 0..<height {
            for _ in 0..<width {
                let r = UInt16(memoryPool[index + 0])
                let g = UInt16(memoryPool[index + 1])
                let b = UInt16(memoryPool[index + 2])
                let a = UInt16(memoryPool[index + 3])
                
                memoryPool[index + 0] = reflect(r, UInt16(color.r * 255))
                memoryPool[index + 1] = reflect(g, UInt16(color.g * 255))
                memoryPool[index + 2] = reflect(b, UInt16(color.b * 255))
                memoryPool[index + 3] = reflect(a, UInt16(color.a * 255))
                
                index += 4
            }
        }
        
        return super.processNone(device)
    }
    
}


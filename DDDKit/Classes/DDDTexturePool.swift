//
//  DDDTexturePool.swift
//  DDDKit
//
//  Created by Guillaume Sabran on 9/30/16.
//  Copyright © 2016 Guillaume Sabran. All rights reserved.
//

import Foundation
import OpenGLES

class DDDTexturePool: DDDObject {
	private var slots: [DDDTextureSlot]
	private var availableSlots: [Int]
	static var poolId = 0
	let id: Int

	override init() {
		id = DDDTexturePool.poolId
		DDDTexturePool.poolId += 1
		var maxNumberOfTextures = GLint()
		glGetIntegerv(GLenum(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS), &maxNumberOfTextures)
		availableSlots = [Int]()
		slots = [DDDTextureSlot]()

		super.init()

		(0..<Int(maxNumberOfTextures)).reversed().forEach { i in
			slots.append(DDDTextureSlot(index: slots.count, pool: self))
			availableSlots.append(i)
		}
	}

	func getNewTextureSlot(for property: SlotDependent) -> DDDTextureSlot? {
		let availableSlot = availableSlots.popLast()
		if availableSlot != nil {
			let slot = slots[availableSlot!]
			slot.usedBy = property
			return slot
		}
		for slot in slots {
			if slot.usedBy?.canReleaseSlot() != false {
				slot.usedBy?.willLoseSlot()
				slot.usedBy = property
				return slot
			}
		}
		return nil
	}

	func release(slot: DDDTextureSlot) {
		slot.usedBy = nil
		availableSlots.append(slot.index)
	}
}

class DDDTextureSlot {
	fileprivate let index: Int
	var id: GLint
	var glId: GLenum
	var description: String
	weak var usedBy: SlotDependent? = nil
	weak var pool: DDDTexturePool? = nil

	init(index: Int, pool: DDDTexturePool) {
		self.index = index
		id = GLint(index)
		glId = GLenum(GL_TEXTURE0 + Int32(index))
		description = "texture\(index)"
		self.pool = pool
	}

	func release() {
		pool?.release(slot: self)
	}
}

protocol SlotDependent: class {
	func willLoseSlot()
	func canReleaseSlot() -> Bool
}

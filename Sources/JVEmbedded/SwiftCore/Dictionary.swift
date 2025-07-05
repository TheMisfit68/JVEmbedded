// Dictionary.swift
// JVEmbedded
//
// Created by Jan Verrept on 03/07/2025.

#if hasFeature(Embedded)

extension JVEmbedded {
	
	public struct KeyValuePair<K: Equatable, V> {
		public let key: K
		public let value: V
	}
	
	public struct Dictionary<K: Equatable, V> {
		
		public typealias Element = KeyValuePair<K, V>

		private var items: [KeyValuePair<K, V>] = []
		
		public var count: Int {
			items.count
		}
		
		public init(_ pairs: [KeyValuePair<K, V>]) {
			self.items = pairs
		}
		
		public init() {
			self.init([])
		}
		
		public mutating func setValue(_ value: V, forKey key: K) {
			if let index = items.firstIndex(where: { $0.key == key }) {
				items[index] = KeyValuePair(key: key, value: value)
			} else {
				items.append(KeyValuePair(key: key, value: value))
			}
		}
		
		public func value(forKey key: K) -> V? {
			items.first(where: { $0.key == key })?.value
		}
		
		public mutating func removeValue(forKey key: K) {
			items.removeAll { $0.key == key }
		}
		
		public var allPairs: [KeyValuePair<K, V>] {
			items
		}
		
		
		public subscript(key: K) -> V? {
			get { value(forKey: key) }
			set {
				if let newValue {
					setValue(newValue, forKey: key)
				} else {
					removeValue(forKey: key)
				}
			}
		}
		
	}

}

extension JVEmbedded.Dictionary: Sequence {
	
	public func makeIterator() -> IndexingIterator<[JVEmbedded.KeyValuePair<K, V>]> {
		items.makeIterator()
	}
}

#endif

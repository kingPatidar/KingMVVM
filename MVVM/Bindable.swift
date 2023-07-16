//
//  Bindable.swift

//
//  Created by MacBook on 16/07/23.
//

import Foundation
class Bindable<T> {
    var value : T? {
        didSet {
            observer?(value)
        }
    }
    
    var observer: ((T?) -> ())?
    
    func bind(observer : @escaping ((T?) -> ()))  {
        self.observer = observer
    }
}

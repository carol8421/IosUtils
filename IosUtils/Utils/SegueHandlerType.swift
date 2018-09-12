/* The SegueHandlerType pattern, as seen on [1, 2], adapted for the changed Swift 3 syntax.
 [1] https://developer.apple.com/library/content/samplecode/Lister/Listings/Lister_SegueHandlerType_swift.html
 [2] https://www.natashatherobot.com/protocol-oriented-segue-identifiers-swift/
 */

import UIKit

public protocol SegueHandlerType {
    
    // `typealias` has been changed to `associatedtype` for Protocols in Swift 3.
    associatedtype SegueIdentifier: RawRepresentable
}

public extension SegueHandlerType where Self: UIViewController, SegueIdentifier.RawValue == String {
    
    // This used to be `performSegueWithIdentifier(...)`.
    public func performSegue(_ identifier: SegueIdentifier, sender: Any?) {
        performSegue(withIdentifier: identifier.rawValue, sender: sender)
    }
    
    public func performSegue(_ identifier: SegueIdentifier) {
        performSegue(withIdentifier: identifier.rawValue, sender: nil)
    }
    
    public func segueIdentifier(for segue: UIStoryboardSegue) -> SegueIdentifier {
        guard let identifier = segue.identifier, let segueIdentifier = SegueIdentifier(rawValue: identifier) else {
            fatalError("Couldn't handle segue identifier \(String(describing: segue.identifier)) for view controller of type \(type(of: self)).")
        }
        
        return segueIdentifier
    }
}

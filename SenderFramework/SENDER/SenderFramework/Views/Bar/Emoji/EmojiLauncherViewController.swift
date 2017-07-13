//
//  EmojiLauncherViewController.swift
//  SENDER
//
//  Created by Roman Serga on 16/2/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import UIKit

let storyboardFileName = "EmojiLauncher"
let controllerIdentifier = "EmojiLauncherViewController"
let emojiCellIdentifier = "emojiCell"

@objc class EmojiLauncherCell : UICollectionViewCell {
    
    @IBOutlet fileprivate weak var titleLabel : UILabel!

}

@objc public protocol EmojiLauncherViewControllerDelegate {
    func emojiLauncherDidSelectedEmoji(_ emoji : String)
    func emojiLauncherDidSelectedBackspace()
}

@objc open class EmojiLauncherViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    open weak var delegate : EmojiLauncherViewControllerDelegate?

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    var emojiArray = [String]()
    
    open static func controller() -> EmojiLauncherViewController {
        guard let senderFrameworkBundle = Bundle.senderFrameworkResources else {
            fatalError("Cannot load SenderFrameworkBundle.")
        }
        let storyboard = UIStoryboard(name: storyboardFileName, bundle: senderFrameworkBundle)
        return storyboard.instantiateViewController(withIdentifier: controllerIdentifier) as! EmojiLauncherViewController
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        if let path = Bundle.senderFrameworkResources?.path(forResource: "Emoji", ofType: "plist") {
            if let stringsArray = NSArray(contentsOfFile: path) as? [String] {
                emojiArray = stringsArray
            }
        }
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojiArray.count
    }

    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: emojiCellIdentifier, for: indexPath)
        
        if let emojiCell = cell as? EmojiLauncherCell {
            emojiCell.titleLabel.text = emojiArray[(indexPath as NSIndexPath).item]
        }
        
        return cell
    }

    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let emojiCell = collectionView.cellForItem(at: indexPath) as? EmojiLauncherCell {
            if let emoji = emojiCell.titleLabel.text {
                delegate?.emojiLauncherDidSelectedEmoji(emoji)
            }
        }
    }
    
    @IBAction func backspace(_ sender : AnyObject) {
        delegate?.emojiLauncherDidSelectedBackspace()
    }
}

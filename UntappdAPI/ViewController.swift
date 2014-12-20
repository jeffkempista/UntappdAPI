//
//  ViewController.swift
//  UntappdAPI
//
//  Created by Jeff Kempista on 12/8/14.
//  Copyright (c) 2014 Jeff Kempista. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UITableViewController {

    var wishlist = [WishlistItemInfo]()
    
    var populatingUserInfo = false
    var populatingWishList = false
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var firstnameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUserInfo()
        refreshData()
    }
    
    @IBAction func signInButtonTapped(sender: UIButton) {
        Untappd.authenticate({ (url) -> Void in
            UIApplication.sharedApplication().openURL(url)
            return
        }, successHandler: { [unowned self] in
            self.refreshData()
        })
    }
    
    func refreshData() {
        if let accessToken = Untappd.Router.accessToken {
            signInButton.hidden = true
            populateUserInfo()
            populateWishList()
        }
    }
    
    func setupUserInfo() {
        self.firstnameLabel.text = ""

        self.avatarImageView.layer.cornerRadius = CGRectGetWidth(self.avatarImageView.bounds) / 2.0
    }
    
    func populateUserInfo() {
        
        if (populatingUserInfo) {
            return
        }
        populatingUserInfo = true
        
        Alamofire.request(Untappd.Router.UserInfo()).validate().responseObject() {
            [unowned self] (_, _, user: User?, _) in

            if let user = user {
                self.firstnameLabel.text = user.firstName
                
                if let avatarURL = user.userAvatarHD {
                    Alamofire.request(.GET, avatarURL).validate(contentType: ["image/*"]).responseImage() {
                        [unowned self] (_, _, image, error) in
                        self.avatarImageView.image = image
                    }
                }
            }
            self.populatingUserInfo = false
        }
    }
    
    func populateWishList() {
        if (populatingWishList) {
            return
        }
        populatingWishList = true
        
        Alamofire.request(Untappd.Router.Wishlist()).validate().responseCollection() {
            [unowned self] (_, _, wishlistItemsArray: [WishlistItemInfo]?, _) in
            
            if let wishlistItems = wishlistItemsArray {
                self.wishlist = wishlistItems
                
                self.tableView.reloadData()
            }
            self.populatingWishList = false
        }
    }
    
}

extension ViewController: UITableViewDataSource {
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wishlist.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let wishlistItem = self.wishlist[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("WishListBeerCell", forIndexPath: indexPath) as UITableViewCell
        
        cell.textLabel?.text = wishlistItem.beer.beerName
        cell.detailTextLabel?.text = wishlistItem.brewery.breweryName
        
        return cell
    }
    
}


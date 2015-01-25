//
//  Untappd.swift
//  UntappdAPI
//
//  Created by Jeff Kempista on 12/8/14.
//  Copyright (c) 2014 Jeff Kempista. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

@objc public protocol ResponseCollectionSerializable {
    class func collection(#response: NSHTTPURLResponse, representation: AnyObject) -> [Self]
}

extension Alamofire.Request {
    public func responseCollection<T: ResponseCollectionSerializable>(completionHandler: (NSURLRequest, NSHTTPURLResponse?, [T]?, NSError?) -> Void) -> Self {
        let serializer: Serializer = { (request, response, data) in
            let JSONSerializer = Request.JSONResponseSerializer(options: .AllowFragments)
            let (JSON: AnyObject?, serializationError) = JSONSerializer(request, response, data)
            if (response != nil && JSON != nil) {
                return (T.collection(response: response!, representation: JSON!), nil)
            } else {
                return (nil, serializationError)
            }
        }
        
        return response(serializer: serializer, completionHandler: { (request, response, object, error) in
            completionHandler(request, response, object as? [T], error)
        })
    }
}

@objc public protocol ResponseObjectSerializable {
    init(response: NSHTTPURLResponse, representation: AnyObject)
}

extension Alamofire.Request {
    public func responseObject<T: ResponseObjectSerializable>(completionHandler: (NSURLRequest, NSHTTPURLResponse?, T?, NSError?) -> Void) -> Self {
        let serializer: Serializer = { (request, response, data) in
            let JSONSerializer = Request.JSONResponseSerializer(options: .AllowFragments)
            let (JSON: AnyObject?, serializationError) = JSONSerializer(request, response, data)
            if (response != nil && JSON != nil) {
                return (T(response: response!, representation: JSON!), nil)
            } else {
                return (nil, serializationError)
            }
        }
        
        return response(serializer: serializer, completionHandler: { (request, response, object, error) in
            completionHandler(request, response, object as? T, error)
        })
    }
}

extension Alamofire.Request {
    class func imageResponseSerializer() -> Serializer {
        return { request, response, data in
            if (data == nil) {
                return (nil, nil)
            }
            
            let image = UIImage(data: data!, scale: UIScreen.mainScreen().scale)
            
            return (image, nil)
        }
    }
    
    func responseImage(completionHandler: (NSURLRequest, NSHTTPURLResponse?, UIImage?, NSError?) -> Void) -> Self {
        return response(serializer: Request.imageResponseSerializer(), completionHandler: { (request, response, image, error) in
            completionHandler(request, response, image as? UIImage, error)
        })
    }
}

public struct Untappd {
    
    private static let clientId = "UNTAPPDAPI_CLIENT_ID"
    private static let clientSecret = "UNTAPPDAPI_CLIENT_SECRET"
    private static let callbackURL = "UNTAPPDAPI_CALLBACK_URL"
    
    enum Router: URLRequestConvertible {
        static let baseURLString = "https://api.untappd.com"
        
        static var accessToken: String? {
            didSet {
                if (accessToken != nil) {
                    Untappd.onSuccess()
                    Untappd.onSuccess = {}
                }
            }
        }
        
        case UserInfo
        case Checkins
        case Wishlist
        
        var URLRequest: NSURLRequest {
            let (path: String, parameters: [String: AnyObject]) = {
                var params = [String: AnyObject]()
                if let token = Router.accessToken {
                    params["access_token"] = token ?? ""
                } else {
                    params["client_id"] = Untappd.clientId ?? ""
                    params["client_secret"] = Untappd.clientSecret ?? ""
                }
                switch self {
                case .UserInfo:
                    params["compact"] = "true"
                    return ("/v4/user/info/", params)
                case .Checkins:
                    return ("/v4/user/checkins", params)
                case .Wishlist:
                    return ("/v4/user/wishlist", params)
                }
            }()
            
            let URL = NSURL(string: Router.baseURLString)
            let URLRequest = NSURLRequest(URL: URL!.URLByAppendingPathComponent(path))
            let encoding = Alamofire.ParameterEncoding.URL
            
            return encoding.encode(URLRequest, parameters: parameters).0
        }
    }
    
    
    private static var authenticationURL: String {
        return "https://untappd.com/oauth/authenticate/?client_id=\(clientId)&response_type=token&redirect_url=\(callbackURL)"
    }
    
    private static var onSuccess: (Void -> Void) = {}
    
    static func authenticate(urlHandler: (NSURL -> Void), successHandler: (Void -> Void)? = nil) {
        if (Untappd.Router.accessToken == nil) {
            let authenticationURLString = authenticationURL.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
            
            let url = NSURL(string: authenticationURLString)!
            
            urlHandler(url)
            if successHandler != nil {
                onSuccess = successHandler!
            }
        }
    }
}

final class CheckinInfo: ResponseCollectionSerializable {
    
    class func collection(#response: NSHTTPURLResponse, representation: AnyObject) -> [CheckinInfo] {
        var checkins = [CheckinInfo]()

        for checkin in representation.valueForKeyPath("response.checkins.items") as [NSDictionary] {
            checkins.append(CheckinInfo(JSON: checkin))
        }
        
        return checkins
    }
    
    let checkinIdentifier: Int
    let createdAt: String
    
    var comment: String?
    var ratingScore: Int?
    
    init(JSON: AnyObject) {
        self.checkinIdentifier = JSON.valueForKeyPath("checkin_id") as Int
        self.createdAt = JSON.valueForKeyPath("created_at") as String
        
        self.comment = JSON.valueForKeyPath("checkin_comment") as? String
        self.ratingScore = JSON.valueForKeyPath("rating_score") as? Int
    }
    
}

final class WishlistItemInfo: ResponseCollectionSerializable {
    
    class func collection(#response: NSHTTPURLResponse, representation: AnyObject) -> [WishlistItemInfo] {
        var wishlistItems = [WishlistItemInfo]()
        
        for wishlistItem in representation.valueForKeyPath("response.beers.items") as [NSDictionary] {
            wishlistItems.append(WishlistItemInfo(JSON: wishlistItem))
        }
        
        return wishlistItems
    }
    
    let createdAt: String
    let beer: Beer
    var brewery: Brewery
    
    init(JSON: AnyObject) {
        self.createdAt = JSON.valueForKeyPath("created_at") as String
        self.beer = Beer(JSON: JSON.valueForKeyPath("beer") as AnyObject!)
        self.brewery = Brewery(JSON: JSON.valueForKeyPath("brewery") as AnyObject!)
    }

}

class User: ResponseObjectSerializable {
    
    let userIdentifier: Int
    let userName: String
    
    var firstName: String?
    var lastName: String?
    var location: String?
    
    var totalBadges: Int?
    var totalBeers: Int?
    var totalCheckins: Int?
    var totalCreatedBeers: Int?
    var totalFollowings: Int?
    var totalFriends: Int?
    var totalPhotos: Int?
    
    var userAvatar: String?
    var userAvatarHD: String?
    var userCoverPhoto: String?
    
    required init(response: NSHTTPURLResponse, representation: AnyObject) {
        self.userIdentifier = representation.valueForKeyPath("response.user.id") as Int
        self.userName = representation.valueForKeyPath("response.user.user_name") as String
        
        self.firstName = representation.valueForKeyPath("response.user.first_name") as String?
        self.lastName = representation.valueForKeyPath("response.user.last_name") as String?
        self.location = representation.valueForKeyPath("response.user.location") as String?
        
        self.totalBadges = representation.valueForKeyPath("response.user.stats.total_badges") as Int?
        self.totalBeers = representation.valueForKeyPath("response.user.stats.total_beers") as Int?
        self.totalCheckins = representation.valueForKeyPath("response.user.stats.total_checkins") as Int?
        self.totalCreatedBeers = representation.valueForKeyPath("response.user.stats.total_created_beers") as Int?
        self.totalFollowings = representation.valueForKeyPath("response.user.stats.total_followings") as Int?
        self.totalFriends = representation.valueForKeyPath("response.user.stats.total_friends") as Int?
        self.totalPhotos = representation.valueForKeyPath("response.user.stats.total_photos") as Int?
        
        self.userAvatar = representation.valueForKeyPath("response.user.user_avatar") as String?
        self.userAvatarHD = representation.valueForKeyPath("response.user.user_avatar_hd") as String?
        self.userCoverPhoto = representation.valueForKeyPath("response.user.user_cover_photo") as String?
    }
    
}

class Beer {
    
    let beerIdentifier: Int
    let createdAt: String
    
    var authRating: Int?
    var beerAbv: Float?
    var beerDescription: String?
    var beerIbu: Int?
    var beerLabel: String?
    var beerName: String?
    var beerSlug: String?
    var beerStyle: String?
    var inProduction: Bool
    var ratingCount: Int?
    var ratingScore: Float?
    var belongsToUsersWishlist: Bool
    
    init(JSON: AnyObject) {
        self.beerIdentifier = JSON.valueForKeyPath("bid") as Int
        self.createdAt = JSON.valueForKeyPath("created_at") as String
        
        self.authRating = JSON.valueForKeyPath("auth_rating") as? Int
        self.beerAbv = JSON.valueForKeyPath("beer_abc") as? Float
        self.beerDescription = JSON.valueForKeyPath("beer_description") as? String
        self.beerIbu = JSON.valueForKeyPath("beer_ibu") as? Int
        self.beerLabel = JSON.valueForKeyPath("beer_label") as? String
        self.beerName = JSON.valueForKeyPath("beer_name") as? String
        self.beerSlug = JSON.valueForKeyPath("beer_slug") as? String
        self.beerStyle = JSON.valueForKeyPath("beer_style") as? String
        self.inProduction = JSON.valueForKeyPath("is_in_production") as? Int == 1
        self.ratingCount = JSON.valueForKeyPath("rating_count") as? Int
        self.ratingScore = JSON.valueForKeyPath("rating_score") as? Float
        self.belongsToUsersWishlist = JSON.valueForKeyPath("wish_list") as? Int == 1
    }
    
}

class Brewery {
    
    let breweryIdentifier: Int
    
    var breweryName: String?
    var brewerySlug: String?
    var breweryLabel: String?
    var countryName: String?
    var twitter: String?
    var facebook: String?
    var instagram: String?
    var url: String?
    var city: String?
    var state: String?
    var latitude: Double?
    var longitude: Double?
    
    init(JSON: AnyObject) {
        self.breweryIdentifier = JSON.valueForKeyPath("brewery_id") as Int
        
        self.breweryName = JSON.valueForKeyPath("brewery_name") as String?
        self.brewerySlug = JSON.valueForKeyPath("brewery_slug") as String?
        self.breweryLabel = JSON.valueForKeyPath("brewery_label") as String?
        self.countryName = JSON.valueForKeyPath("country_name") as String?
        
        self.twitter = JSON.valueForKeyPath("contact.twitter") as String?
        self.facebook = JSON.valueForKeyPath("contact.facebook") as String?
        self.instagram = JSON.valueForKeyPath("contact.instagram") as String?
        self.url = JSON.valueForKeyPath("contact.url") as String?
        
        self.city = JSON.valueForKeyPath("location.brewery_city") as String?
        self.state = JSON.valueForKeyPath("location.brewery_state") as String?
        self.latitude = JSON.valueForKeyPath("location.lat") as Double?
        self.longitude = JSON.valueForKeyPath("location.lng") as Double?
    }
    
}

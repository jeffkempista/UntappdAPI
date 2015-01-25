//
//  BeerSearchViewController.swift
//  UntappdAPI
//
//  Created by Jeff Kempista on 1/25/15.
//  Copyright (c) 2015 Jeff Kempista. All rights reserved.
//

import UIKit
import Alamofire

class BeerSearchViewController: UIViewController {

    var searchResults = [BeerSearchResult]()
    var selectedBeerInfo: BeerSearchResult? {
        didSet {
            if let searchDisplayController = self.searchDisplayController {
                searchDisplayController.setActive(false, animated: true)
                if let selectedBeerInfo = selectedBeerInfo {
                    setupBeerInfo(selectedBeerInfo)
                }
            }
        }
    }
    
    var searchInProgress = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tableViewCellNib = UINib(nibName: "BeerSearchResultTableViewCell", bundle: nil)
        self.searchDisplayController?.searchResultsTableView.registerNib(tableViewCellNib, forCellReuseIdentifier: "BeerSearchResultCell")
    }

    func performSearch(query: String) {
        self.searchInProgress = true
        Alamofire.request(Untappd.Router.BeerSearch(query: query)).validate().responseCollection() {
            (_, _, beerSearchResults: [BeerSearchResult]?, _) in
            
            if let beerSearchResults = beerSearchResults {
                self.searchResults = beerSearchResults
                
                if (self.searchInProgress) {
                    if let searchResultsTableView = self.searchDisplayController?.searchResultsTableView {
                        searchResultsTableView.reloadData()
                    }
                    self.searchInProgress = false
                }
            }
        }
    }
    
    func setupBeerInfo(beerInfo: BeerSearchResult) {
        println("setupBeerData for \(beerInfo.beer.beerName)")
    }
}

extension BeerSearchViewController: UITableViewDataSource {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let beerItem = self.searchResults[indexPath.row]
        
        let cell = tableView.dequeueReusableCellWithIdentifier("BeerSearchResultCell", forIndexPath: indexPath) as UITableViewCell
        
        cell.textLabel?.text = beerItem.beer.beerName
        cell.detailTextLabel?.text = beerItem.brewery.breweryName
        
        return cell
    }
    
}

extension BeerSearchViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedBeerInfo = searchResults[indexPath.row]
    }
}

extension BeerSearchViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if let query = searchBar.text {
            self.searchInProgress = true
            performSearch(query)
        }
    }
}

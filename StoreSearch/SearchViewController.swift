//
//  ViewController.swift
//  StoreSearch
//
//  Created by Rigoberto Dominguez on 07/03/23.
//

import UIKit

class SearchViewController: UIViewController {
    
    @IBOutlet weak var searchBar : UISearchBar!
    @IBOutlet weak var tableView : UITableView!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var landscapeVC: LandscapeViewController?
    
    private let search = Search()
    
    struct TableView {
        struct CellIdentifiers {
            static let searchResultCell = "SearchResultCell"
            static let nothingFoundCell = "NothingFoundCell"
            static let loadingCell = "LoadingCell"
        }
    }

    
    // MARK: - viewDidLoad()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsets(top: 91, left: 0, bottom: 0, right: 0)
        
        var cellNib = UINib(nibName: TableView.CellIdentifiers.searchResultCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableView.CellIdentifiers.searchResultCell)
        cellNib = UINib(nibName: TableView.CellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableView.CellIdentifiers.nothingFoundCell)
        cellNib = UINib(nibName: TableView.CellIdentifiers.loadingCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableView.CellIdentifiers.loadingCell)
        
        searchBar.becomeFirstResponder()
        
    }
    
// MARK: - Rotation
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        switch newCollection.verticalSizeClass {
        case .compact:
            showLandscape(with: coordinator)
        case .regular, .unspecified :
            hideLandscape(with: coordinator)
        @unknown default:
            break
        }
    }
    
// MARK: - Helper Methods
    
    func showLandscape (with coordinator: UIViewControllerTransitionCoordinator){
        // 1
        guard landscapeVC == nil else {return}
        
        //2
        landscapeVC = storyboard!.instantiateViewController(withIdentifier: "LandscapeViewController") as? LandscapeViewController
        if let controller = landscapeVC {
            controller.search = search
            //3
            controller.view.frame = view.bounds
            controller.view.alpha = 0
            //4
            view.addSubview(controller.view) // Add to parent
            addChild(controller) // Add to the parent ViewController
            
            coordinator.animate(alongsideTransition: { _ in
                controller.view.alpha = 1
                self.searchBar.resignFirstResponder()
                if self.presentedViewController != nil {
                    self.dismiss(animated: true, completion: nil)
                }
            }, completion: { _ in
                controller.didMove(toParent: self)
            })
        }
    }
    
    func hideLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
        if let controller = landscapeVC {
            controller.willMove(toParent: nil)
            coordinator.animate(alongsideTransition: {_ in
                controller.view.alpha = 0
            }, completion: { _ in
                controller.view.removeFromSuperview() //Remove form Parent ViewController
                controller.removeFromParent() // Remove from Parent
                self.landscapeVC = nil
            })
        }
    }
    
    
    /*
     
     // obteniendo Data sin el uso de URLSession
     
     func performStoreRequest(with url:URL) -> Data? {
        do {
            return try Data(contentsOf: url)
        } catch {
            print("Download Error \(error.localizedDescription)")
            showNetworkError()
            return nil
        }
    }*/
    
    
    
    func showNetworkError(){
        
        let alert = UIAlertController(title: "Whoops...", message: "There was an error accessing the iTunes Store. Please try again.", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
        
    }

    
    @IBAction func segmentedChanged(_ sender: UISegmentedControl) {
        performSearch()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "ShowDetail" {
            let detailViewController = segue.destination as! DetailViewController
            let indexPath = sender as! IndexPath
            let searchResult = search.searchResults[indexPath.row]
            detailViewController.searchResult = searchResult
        }
    }
    
    
}

// MARK: - Search Bar Delegate

extension SearchViewController : UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }
    
    func performSearch() {
        
        search.performSearch(for: searchBar.text!, category: segmentedControl.selectedSegmentIndex) { success in
            if !success {
                self.showNetworkError()
            }
            self.tableView.reloadData()
        }
        
        tableView.reloadData()
        searchBar.resignFirstResponder()
        

            
            /*
            // Uso de Queue Dispatchers
            let queue = DispatchQueue.global()
            let url = self.iTunesURL(searchText: searchBar.text!)
            print("URL: \(url)")
            
            queue.async {
                if let data = self.performStoreRequest(with: url) {
                    /*let results = parse(data: data)
                    print("Got Result \(results)")*/
                    self.searchResults = self.parse(data: data)
                    self.searchResults.sort(by: <)
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.tableView.reloadData()
                    }
                    return
                }
            }*/
    }
    
    func position (for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
}

// MARK: - Table View Delegate

extension SearchViewController : UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if search.isLoading {
            return 1
        } else if !search.hasSearched {
            return 0
        } else if search.searchResults.count == 0 {
            return 1
        } else {
            return search.searchResults.count
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                        
        if search.isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.loadingCell, for: indexPath)
            let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spinner.startAnimating()
            return cell
        }
        
        if search.searchResults.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.nothingFoundCell, for: indexPath)
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.searchResultCell, for: indexPath) as! SearchResultCell
            
            let searchResult = search.searchResults[indexPath.row]
            
            cell.configure(for: searchResult)
            
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "ShowDetail", sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if search.searchResults.count == 0 || search.isLoading {
            return nil
        } else {
            return indexPath
        }
    }
}


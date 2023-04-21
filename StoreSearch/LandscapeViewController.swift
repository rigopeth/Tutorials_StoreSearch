//
//  LandscapeViewController.swift
//  StoreSearch
//
//  Created by Rigoberto Dominguez Garcia on 20/04/23.
//

import UIKit

class LandscapeViewController: UIViewController {
    
    var search : Search!
    
    private var firstTime = true
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var pageControl: UIPageControl!
    
    private var donwloads = [URLSessionDownloadTask]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.removeConstraints(view.constraints)
        view.translatesAutoresizingMaskIntoConstraints = true
        
        pageControl.removeConstraints(pageControl.constraints)
        pageControl.translatesAutoresizingMaskIntoConstraints = true
        
        scrollView.removeConstraints(scrollView.constraints)
        scrollView.translatesAutoresizingMaskIntoConstraints = true
        
        view.backgroundColor = UIColor(patternImage: UIImage(named: "LandscapeBackground")!)
        pageControl.numberOfPages = 0
        
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let safeFrame = view.safeAreaLayoutGuide.layoutFrame
        scrollView.frame = safeFrame
        pageControl.frame = CGRect(
            x: safeFrame.origin.x,
            y: safeFrame.size.height - pageControl.frame.size.height,
            width: safeFrame.size.width,
            height: pageControl.frame.size.height)
        
        if firstTime {
            firstTime = false
            
            switch search.state {
            case .notSearchedYet, .loading, .noResults:
                break
            case .results(let list):
                tileButtons(list)
            }
            
        }
        
    }
    
    // MARK: - private Methods
    
    private func tileButtons(_ searchResults: [SearchResult]){
        let itemWidth: CGFloat = 94
        let itemHeight: CGFloat = 88
        var columnsPerPage = 0
        var rowsPerPage = 0
        var marginX: CGFloat = 0
        var marginY: CGFloat = 0
        let viewWidth = scrollView.bounds.size.width
        let viewHeight = scrollView.bounds.size.height
        
        //1
        columnsPerPage = Int(viewWidth/itemWidth)
        rowsPerPage = Int(viewHeight/itemHeight)
        
        //2
        marginX = (viewWidth - (CGFloat(columnsPerPage) * itemWidth )) * 0.5
        marginY = (viewHeight - (CGFloat(rowsPerPage) * itemHeight )) * 0.5

        let buttonWidth: CGFloat = 82
        let buttonHeight: CGFloat = 82
        let paddingHorz = (itemWidth - buttonWidth) / 2
        let paddingVert = (itemHeight - buttonHeight) / 2
        
        //Add the buttons
        
        var row = 0
        var column = 0
        
        var x = marginX
        for(index, result) in searchResults.enumerated(){
            //1
            let button = UIButton(type: .custom)
            button.setBackgroundImage(UIImage(named: "LandscapeButton"),for: .normal)
            donwloadImage(for: result, andPlaceOn: button)
            //2
            button.frame = CGRect(x: x + paddingHorz, y: marginY + CGFloat(row) * itemHeight + paddingVert, width: buttonWidth, height: buttonHeight)
            //3
            scrollView.addSubview(button)
            //4
            row += 1
            if row == rowsPerPage {
               row = 0; x += itemWidth; column += 1
               if column == columnsPerPage {
                 column = 0; x += marginX * 2
               }
             }
        }
        
        let buttonsPerPage = columnsPerPage * rowsPerPage
        let numPages =  1 + (searchResults.count - 1) / buttonsPerPage
        scrollView.contentSize = CGSize(width: CGFloat(numPages) * viewWidth, height: scrollView.bounds.size.height)
        
        pageControl.numberOfPages = numPages
        pageControl.currentPage = 0
        
        print("Number of pages \(numPages)")
        
    }
    
    deinit{
        print("deinit \(self)")
        for task in donwloads{
            task.cancel()
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func pageChanged(_ sender: UIPageControl){
        
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       options: [.curveEaseOut],
                       animations: {
            self.scrollView.contentOffset = CGPoint(
                x: self.scrollView.bounds.size.width * CGFloat(sender.currentPage),
                y: 0)
        },
        completion: nil)
    }
    
    // MARK: - Display Buttons Images
    private func donwloadImage(for searchResult: SearchResult, andPlaceOn button : UIButton){
        if let url = URL(string: searchResult.imageSmall) {
            let task = URLSession.shared.downloadTask(with: url) {
                [weak button] url, _ , error in
                if error == nil, let url = url,
                    let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        if let button = button {
                            button.setImage(image, for: .normal)
                        }
                    }
                }
            }
            task.resume()
            donwloads.append(task)
        }
        
    }

}

extension LandscapeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.bounds.size.width
        let page = Int((scrollView.contentOffset.x + width / 2) / width)
        pageControl.currentPage = page
    }
}

//
//  ViewController.swift
//  SwiftTwitterSample
//
//  Created by ucuc on 2/15/15.
//  Copyright (c) 2015 ucuc. All rights reserved.
//

import UIKit
import Social
import Accounts

class TimelineViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet var tweetTableView: UITableView!
    var dataSource = [AnyObject]()
    var twAccount: ACAccount?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        getTimeline()
        
        // pull to refresh
        var refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: Selector("getTimeline"), forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refreshControl
        
        // resize cells according to the text they hold
        self.tableView.estimatedRowHeight = 90
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // tweet
    @IBAction func pressComposeButton() {
        if ( SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter )) {
            var tweetSheet:SLComposeViewController = SLComposeViewController( forServiceType: SLServiceTypeTwitter )
            self.presentViewController(tweetSheet, animated: true, completion: nil)
        } else {
            var alert = UIAlertController(title: "Accounts", message: "Please login to a Twitter account", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    // get twitter account
    private func getAccount(){
        var accountStore = ACAccountStore()
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccountsWithType(accountType, options: nil) { (granted:Bool, error:NSError?) -> Void in
            if error != nil {
                println("error! \(error)")
                return
            }
            
            if !granted {
                println("error! Twitterアカウントの利用が許可されていません")
                return
            }
            
            let accounts = accountStore.accountsWithAccountType(accountType) as [ACAccount]
            if accounts.count == 0 {
                println("error! 設定画面からアカウントを設定してください")
                return
            }
            self.twAccount = accounts[0]
            self.getTimeline()
        }
    }
    
    // get user's home timeline
    func getTimeline() {
        if twAccount == nil {
            getAccount()
            return
        }
        
        let URL = NSURL(string: "https://api.twitter.com/1.1/statuses/home_timeline.json")

        /*
        let parameters = ["screen_name" : "@hoge",
            "include_rts" : "0",
            "trim_user" : "1",
            "count" : "20"]*/
        
        let request = SLRequest(
            forServiceType: SLServiceTypeTwitter,
            requestMethod: SLRequestMethod.GET,
            URL: URL,
            parameters: nil)
        
        request.account = self.twAccount
        
        request.performRequestWithHandler { (responseData, urlResponse, error) -> Void in
            if error != nil {
                println("error is \(error)")
            } else {
                self.dataSource = NSJSONSerialization.JSONObjectWithData(responseData,options: .AllowFragments,error: nil) as NSArray
                //self.dataSource = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableLeaves, error: nil) as [AnyObject]
                if self.dataSource.count != 0 {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tweetTableView.reloadData()
                        self.refreshControl?.endRefreshing()
                    }
                }
            }
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tweetTableView.dequeueReusableCellWithIdentifier("Cell") as CustomCell
        updateCell(cell, cellForRowAtIndexPath: indexPath)
        return cell
    }
    
    private func updateCell( cell : CustomCell, cellForRowAtIndexPath indexPath : NSIndexPath) {
        let row = indexPath.row
        let tweet = self.dataSource[row] as NSDictionary

        cell.customTitleLabel?.text = tweet.objectForKey("user")?.objectForKey("name") as NSString
        cell.customLabel?.text = tweet.objectForKey("text") as NSString
        cell.imageView?.image = getUIImageFromUIView()
        
        let url = NSURL(string:tweet.objectForKey("user")?.objectForKey("profile_image_url") as NSString)
        let req = NSURLRequest(URL:url!)

        NSURLConnection.sendAsynchronousRequest(req, queue:NSOperationQueue.mainQueue()){(res, data, err) in
            let image = UIImage(data:data)
            cell.imageView?.image = image
        }
        cell.layoutIfNeeded()
    }
    
    // make temporary image
    private func getUIImageFromUIView() -> UIImage
    {
        let size = CGSize(width: 40, height: 40)
        let view:UIView = UIView(frame: CGRect(origin: CGPointZero, size: size))
        view.backgroundColor = UIColor(white: 0.9, alpha: 1.0)

        UIGraphicsBeginImageContextWithOptions(view.frame.size, true, 0);//必要なサイズ確保
        let context:CGContextRef = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(context, -view.frame.origin.x, -view.frame.origin.y);
        view.layer.renderInContext(context);
        let renderedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return renderedImage;
    }
    
    /*
    private func updateVisibleCells () {
        for cell in tweetTableView.visibleCells() {
            updateCell(cell as CustomCell, cellForRowAtIndexPath: tweetTableView.indexPathForCell(cell as CustomCell)!)
        }
    }*/
}


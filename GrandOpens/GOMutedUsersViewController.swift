//
//  GOMutedUsersViewController.swift
//  GrandOpens
//
//  Created by Tony Morales on 1/24/16.
//  Copyright © 2016 Tony Morales. All rights reserved.
//

import UIKit
import ParseUI
import Parse

class GOMutedUsersViewController: PFQueryTableViewController {

    // MARK: Initialization
    
    override init(style: UITableViewStyle, className: String?) {
        super.init(style: style, className: kUserClassKey)
        
        self.pullToRefreshEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Muted Users"
        
        if navigationController != nil {
            let backButton = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
            self.navigationController!.navigationBar.topItem?.backBarButtonItem = backButton
        }
        // Next line prevents empty cells from displaying
        self.tableView.tableFooterView = UIView()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController!.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(26), NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.tabBarController?.tabBar.hidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.objects!.count
    }
    
    
    // MARK: PFQueryTableViewController
    
    override func queryForTable() -> PFQuery {
        if (PFUser.currentUser() == nil) {
            let query = PFQuery(className: self.parseClassName!)
            query.limit = 0
            return query
        }
        
        let activityQuery = PFQuery(className: kUserActivityClassKey)
        activityQuery.whereKey(kUserActivityByUserKey, equalTo: PFUser.currentUser()!)
        activityQuery.whereKey(kUserActivityTypeKey, equalTo: kUserActivityTypeMute)
        activityQuery.includeKey(kUserActivityToUserKey)
        activityQuery.cachePolicy = PFCachePolicy.NetworkElseCache
        return activityQuery
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath, object: PFObject?) -> PFTableViewCell? {
        let cellIdentifier = "UserCell"
        let cell = PFTableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: cellIdentifier)
        
        let user: PFUser = object?.objectForKey(kUserActivityToUserKey) as! PFUser
        if user.objectForKey(kUserDisplayNameKey) == nil || (user.objectForKey(kUserDisplayNameKey))! as! String == "" {
            cell.textLabel!.text = "A No-Namer"
        } else {
            cell.textLabel!.text = user.objectForKey(kUserDisplayNameKey) as? String
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let vc = GOUserProfileViewController()
        let user = objectAtIndexPath(indexPath)?.objectForKey(kUserActivityToUserKey) as! PFUser
        vc.user = user
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }
    
    
    // MARK:-
}

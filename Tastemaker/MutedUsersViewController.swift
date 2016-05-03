//
//  MutedUsersViewController.swift
//  Tastemaker
//
//  Created by Tony Morales on 1/24/16.
//  Copyright © 2016 Tony Morales. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import Firebase

class MutedUsersViewController: UITableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    private var mutedUsersHandle: UInt?
    private var mutedUsers = [User]()
    private let uid: String = NSUserDefaults.standardUserDefaults().objectForKey("uid") as! String
    
    
    // MARK: Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Muted Users"
        self.tableView.emptyDataSetDelegate = self
        self.tableView.emptyDataSetSource = self
        
        if navigationController != nil {
            let backButton = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
            self.navigationController!.navigationBar.topItem?.backBarButtonItem = backButton
        }
        // Next line prevents empty cells from displaying
        self.tableView.tableFooterView = UIView()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController!.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(22), NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.tabBarController?.tabBar.hidden = true
        
        if self.isMovingToParentViewController() {
            mutedUsers = []
            mutedUsersHandle = DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(uid)/mutes").observeEventType(FEventType.Value, withBlock: {
                snapshot in
                
                let enumerator = snapshot.children
                self.mutedUsers = []
                
                while let data = enumerator.nextObject() as? FDataSnapshot {
                    DataService.dataService.USERS_PUBLIC_REF.childByAppendingPath("\(data.key)").observeSingleEventOfType(FEventType.Value, withBlock: {
                        snap in
                        
                        self.mutedUsers.insert(snapshotToUser(snap), atIndex: 0)
                        self.tableView.reloadData()
                    })
                }
            })
        }
        self.tableView.reloadData()
        
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "MutedUsersViewController")
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject: AnyObject])
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.isMovingFromParentViewController() {
            DataService.dataService.USER_ACTIVITIES_REF.childByAppendingPath("\(uid)/mutes").removeObserverWithHandle(mutedUsersHandle!)
        }
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
        return self.mutedUsers.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "UserCell"
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: cellIdentifier)
        
        let user = mutedUsers[indexPath.row]
        cell.textLabel?.text = user.nickname
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let vc = UserProfileViewController(style: UITableViewStyle.Plain)
        let user = mutedUsers[indexPath.row]
        vc.userId = user.id
        vc.userNickname = user.nickname
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }
    
    
    // MARK: DZNEmptyDataSet
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let title = ":-)"
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(50)]
        return NSAttributedString(string: title, attributes: attributes)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let description = "You haven't muted anyone. \nThat's a good thing!"
        let attributes = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)]
        return NSAttributedString(string: description, attributes: attributes)
    }
}
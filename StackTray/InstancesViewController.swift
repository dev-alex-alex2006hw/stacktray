//
//  InstancesViewController.swift
//  StackTray
//
//  Created by Ruben Cagnie on 3/30/15.
//  Copyright (c) 2015 dutchcoders. All rights reserved.
//

import Cocoa

class InstancesViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, AccountControllerObserver {
  override func viewDidAppear() {
    super.viewDidAppear()
    
    if let window = self.view.window {
      window.titleVisibility =  NSWindowTitleVisibility.Visible ;
      window.movableByWindowBackground = true;
      window.titlebarAppearsTransparent = true;
      window.styleMask |= NSFullSizeContentViewWindowMask;
      window.center()
    }
  }
  
  var instances: [Instance] = []
  
  func sortByName(this: Instance, that: Instance) -> Bool {
    return this.name > that.name
  }
  
    /** Account Controller */
    var accountController: AccountController! {
        didSet {
            detailInstanceViewController.accountController = accountController
            reloadInstances()
        }
    }
    
    /** Array that keeps track of the indexes for accounts */
    var accountIndexes: [Int] = []
    /** Array that keeps track of the indexes for instances */
    var instanceIndexes: [Int] = []
    
    /** Reload the instances (calculate the indexes etc) */
    func reloadInstances(){
        
        //Clear the indexes
        accountIndexes.removeAll(keepCapacity: false)
        instanceIndexes.removeAll(keepCapacity: false)
        
        //Set the current index to 0
        var currentIndex = 0
        
        for account in accountController.accounts {
            accountIndexes.append(currentIndex++)
            
            for instance in account.instances {
                instanceIndexes.append(currentIndex++)
            }
        }

        //Reload the table
        accountsTableView.reloadData()
        selectInstance(-1)
    }
    
    /** View Will Appear */
    override func viewWillAppear() {
        super.viewWillAppear()
        accountController.addAccountControllerObserver(self)
    }
    
    /** View Will Disappear */
    override func viewWillDisappear() {
        super.viewWillDisappear()
        accountController.removeAccountControllerObserver(self)
    }
    
    //MARK - Accounts
    func didAddAccountAtIndex(accountController: AccountController, index: Int){
        reloadInstances()
    }
    
    func didDeleteAccountAtIndex(accountController: AccountController, index: Int){
        reloadInstances()
    }
    
    func didUpdateAccountAtIndex(accountController: AccountController, index: Int){
        let accountIndex = accountIndexes[index]
        accountsTableView.reloadDataForRowIndexes(NSIndexSet(index: accountIndex), columnIndexes: NSIndexSet(index: 0))
    }
    
    //MARK - Instances
    func didAddAccountInstance(accountController: AccountController, index: Int, instanceIndex: Int) {
        reloadInstances()
    }
    
    func didUpdateAccountInstance(accountController: AccountController, index: Int, instanceIndex: Int) {
        let account = accountController.accounts[index]
        let instance = account.instances[instanceIndex];
        
        if detailInstanceViewController.instance != nil && detailInstanceViewController.instance == instance {
            detailInstanceViewController.instance = instance
        }
        
        
        let row = accountIndexes[index] + instanceIndex + 1
        accountsTableView.reloadDataForRowIndexes(NSIndexSet(index: row), columnIndexes: NSIndexSet(index: 0))
    }
    
    //MARK: Show instance console
    func showInstanceConsole(accountIndex: Int, instanceIndex: Int){
        let row: Int = accountIndexes[accountIndex] + instanceIndex + 1
        
        accountsTableView.selectRowIndexes(NSIndexSet(index: row), byExtendingSelection: false)
        accountsTableView.scrollRowToVisible(row)
        selectInstance(row)
        detailInstanceViewController.showConsole()
    }

    
    func didDeleteAccountInstance(accountController: AccountController, index: Int, instanceIndex: Int) {
        reloadInstances()
    }
    
    //MARK - Instances Starting/Stopping
    func instanceDidStart(accountController: AccountController, index: Int, instanceIndex: Int) {
        let account = accountController.accounts[index]
        let instance = account.instances[instanceIndex];
        
        if detailInstanceViewController.instance != nil && detailInstanceViewController.instance == instance {
            detailInstanceViewController.instance = instance
        }
    }
    
    func instanceDidStop(accountController: AccountController, index: Int, instanceIndex: Int) {
        let account = accountController.accounts[index]
        let instance = account.instances[instanceIndex];
        
        if detailInstanceViewController.instance != nil && detailInstanceViewController.instance == instance {
            detailInstanceViewController.instance = instance
        }
    }
    
    @IBOutlet weak var accountsTableView: NSTableView!
    @IBOutlet weak var deselectedContentView: NSView!
    @IBOutlet weak var detailContentView: NSView!
        
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return instanceIndexes.count + accountIndexes.count
    }
    
    func accountIndexForIndex(index: Int) -> Int{
        var accountIndex = index-1
        while find(accountIndexes, accountIndex) == nil {
            accountIndex--
        }
        return accountIndex
    }
    
    func objectForRow(row : Int)-> AnyObject?{
        if let index = find(accountIndexes, row) {
            return accountController.accounts[index]
        } else if let index = find(instanceIndexes, row) {
            let accountIndex = accountIndexForIndex(row)
            let instanceIndex = row - accountIndex - 1
            let account = accountController.accounts[find(accountIndexes,accountIndex)!]
            var instances: [Instance] = account.instances // sort(&account.instances, sortByName)
            return instances[instanceIndex]
        } else {
            return nil
        }
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        let object : AnyObject? = objectForRow(row)
        if let account = object as? Account {
            return account.name
        } else if let instance = object as? Instance {
            return instance.name
        } else {
            return nil
        }
    }
    
    func tableView(tableView: NSTableView, isGroupRow row: Int) -> Bool {
        if let account = objectForRow(row) as? Account {
            return true
        } else {
            return false
        }
    }
    
    /** Change the selection of the row */
    func tableView(tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        if let account = objectForRow(row) as? Instance {
            selectInstance(row)
            
            return true
        } else {
            return false
        }
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let object : AnyObject? = objectForRow(row)
        if let account = object as? Account {
            let view = tableView.makeViewWithIdentifier("accountCell", owner: self) as! NSTableCellView
            
            view.textField?.stringValue = account.name
            
            return view
        } else if let instance = object as? Instance {
            let view = tableView.makeViewWithIdentifier("instanceCell", owner: self) as! NSTableCellView
            
            switch instance.state {
            case .Running:
                view.imageView?.image = NSImage(named: "started")
            case .Stopped:
                view.imageView?.image = NSImage(named: "stopped")
            default:
                view.imageView?.image = NSImage(named: "unknown")
            }
            view.textField?.stringValue = instance.name
            
            return view
        } else {
            return nil
        }
    }
    
    /** User selected a row in the table */
    func tableViewSelectionIsChanging(notification: NSNotification) {
        selectInstance(accountsTableView.selectedRow)
    }
    
    func selectInstance(row: Int){
        if row < 0 {
            detailContentView.hidden = true
            deselectedContentView.hidden = false
        } else {
            detailContentView.hidden = false
            deselectedContentView.hidden = true
            
            if let instance = objectForRow(row) as? Instance {
                if instance != detailInstanceViewController.instance {
                    detailInstanceViewController.instance = instance
                }
            }
        }
    }
    
    var detailInstanceViewController : DetailInstanceViewController!
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if let detail = segue.destinationController as? DetailInstanceViewController {
            detailInstanceViewController = detail
        }
    }
}

class DetailInstanceViewController : NSViewController {
    @IBOutlet weak var detailsButton: NSButton!
    @IBOutlet weak var consoleButton: NSButton!
    @IBOutlet weak var configButton: NSButton!
    
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var statusLabel: NSTextField!
    
    lazy var fakFactory: NIKFontAwesomeIconFactory = NIKFontAwesomeIconFactory()
    
    /** Start Stop */
    @IBOutlet weak var startStopButton: NSButton!
    @IBOutlet weak var startStopLabel: NSTextField!
    @IBAction func startOrStop(sender: NSButton) {
        switch instance.state {
        case .Running:
            sender.enabled = false
            accountController.stopInstance(accountController.accountForInstance(instance), instance: instance, callback: { (error) -> Void in
                if error != nil {
                    presentAWSError(error!)
                }
                
                self.updateStateLabel()
            })
        case .Stopped:
            sender.enabled = false
            accountController.startInstance(accountController.accountForInstance(instance), instance: instance, callback: { (error) -> Void in
                if error != nil {
                    presentAWSError(error!)
                }
                
                self.updateStateLabel()
            })
        default:
            break;
        }
        
    }
    
    //MARK: Reboot
    @IBOutlet weak var rebootButton: NSButton! {
        didSet {
        }
    }
    
    @IBAction func rebootInstance(sender: NSButton) {
        sender.enabled = false
        accountController.rebootInstance(accountController.accountForInstance(instance), instance: instance, callback: { (error) -> Void in
            
        })
    }
    
    //MARK: Browse
    @IBOutlet weak var browseButton: NSButton! {
        didSet {
        }
    }
    @IBAction func browseInstance(sender: NSButton) {
        browseToInstance(instance)
    }
    
    //MARK: Connect
    @IBOutlet weak var connectButton: NSButton! {
        didSet {
        }
    }
    
    @IBAction func connect(sender: NSButton) {
        connectToInstance(instance)
    }
    
    func showConsole(){
        self.buttonClicked(consoleButton)
    }
    
    var instance: Instance! {
        didSet {
            tabViewController.instance = instance
            titleLabel.stringValue = instance.name
            updateStateLabel()
        }
    }
    
    var accountController: AccountController! {
        didSet{
            tabViewController.accountController = accountController
        }
    }
    
    var tabViewController : InstanceTabbarController! {
        didSet {
            tabViewController.accountController = accountController
        }
    }
    
    func updateStateLabel(){
        
        
        statusLabel.stringValue = instance.state.description
        switch instance.state {
        case .Running :
            statusLabel.textColor = NSColor.greenColor()
            startStopButton.enabled = true
          startStopButton.image = NSImage(named: "stop-50.png")
//            startStopButton.image = fakFactory.createImageForIcon(NIKFontAwesomeIconStop)
//            startStopLabel.stringValue = "Stop"
        case .Stopped :
            statusLabel.textColor = NSColor.redColor()
            startStopButton.enabled = true
            startStopButton.image = NSImage(named: "play-50.png")
//            startStopButton.image = fakFactory.createImageForIcon(NIKFontAwesomeIconPlay)
//            startStopLabel.stringValue = "Start"
        default :
            statusLabel.textColor = NSColor.blackColor()
            startStopButton.enabled = false
            startStopButton.image = NSImage(named: "play-50.png")
//            startStopButton.image = fakFactory.createImageForIcon(NIKFontAwesomeIconPlay)
//            startStopLabel.stringValue = "Start"
        }
    }
    
    @IBAction func buttonClicked(sender: NSButton) {
        if sender == configButton {
            tabViewController.selectedTabViewItemIndex = 0
        } else if sender == detailsButton {
            tabViewController.selectedTabViewItemIndex = 1
        } else if sender == consoleButton {
            tabViewController.selectedTabViewItemIndex = 2
        }
        
        updateCurrentIndex()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        updateCurrentIndex()
    }
    
    func updateCurrentIndex(){
        configButton.state = tabViewController.selectedTabViewItemIndex == 0 ? NSOnState : NSOffState
        detailsButton.state = tabViewController.selectedTabViewItemIndex == 1 ? NSOnState : NSOffState
        consoleButton.state = tabViewController.selectedTabViewItemIndex == 2 ? NSOnState : NSOffState
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationController as? InstanceTabbarController {
            tabViewController = vc
        }
    }
}

class InstanceTabbarController : NSTabViewController {
    var instance: Instance! {
        didSet{
            for vc in self.tabViewItems as! [NSTabViewItem] {
                if let instanceVc = vc.viewController as? InstanceTabViewController {
                    instanceVc.instance = instance
                }
            }
        }
    }
    
    var accountController: AccountController!{
        didSet{
            for vc in self.tabViewItems as! [NSTabViewItem] {
                if let instanceVc = vc.viewController as? InstanceTabViewController {
                    instanceVc.accountController = accountController
                }
            }
        }
    }
    
}

class InstanceTabViewController: NSViewController {
    var account: Account!
    var instance: Instance! {
        didSet {
            if accountController != nil {
                account = accountController.accountForInstance(instance)
            }
        }
    }
    var accountController: AccountController!
    
    var active : Bool {
        return self.view.window != nil
    }
}

class InstanceSetupTabViewController : InstanceTabViewController {
    @IBOutlet weak var pemKeyField: NSTextField!
    @IBOutlet weak var userIDField: NSTextField!
    
    /** Browse for the pem key */
    @IBAction func browseForPemKey(sender: NSButton) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        let clicked = panel.runModal()
        if clicked == NSFileHandlingPanelOKButton {
            if let url = panel.URL {
                pemKeyField.stringValue = url.path!
            }
        }

    }
    
    @IBAction func saveInstance(sender: AnyObject) {
        instance.pemLocation = pemKeyField.stringValue
        instance.userId = userIDField.stringValue
        
        accountController.saveAccounts()
    }
    
    @IBOutlet weak var internalIPTextField: NSTextField!
    @IBOutlet weak var internalDNSTextField: NSTextField!
    @IBOutlet weak var externalIPTextField: NSTextField!
    @IBOutlet weak var externalDNSTextField: NSTextField!
    
    @IBOutlet weak var internalIPButton: NSButton!
    @IBOutlet weak var internalDNSButton: NSButton!
    @IBOutlet weak var externalIPButton: NSButton!
    @IBOutlet weak var externalDNSButton: NSButton!
    
    @IBAction func copyLink(sender: NSButton) {
        var link: String?
        
        switch sender {
        case internalIPButton:
            link = internalIPTextField.stringValue
        case internalDNSButton:
            link = internalDNSTextField.stringValue
        case externalIPButton:
            link = externalIPTextField.stringValue
        case externalDNSButton:
            link = externalDNSTextField.stringValue
        default:
            break
        }
        
        if link != nil && !link!.isEmpty {
            NotificationManager.sharedManager().saveToClipBoard(link!)
        }
    }
    
    override var instance: Instance! {
        didSet {
            if active {
                reloadLinksForInstance()
            }
        }
    }
    
    func reloadLinksForInstance(){
        internalIPTextField.stringValue = instance.privateIpAddress
        internalDNSTextField.stringValue = instance.privateDnsName
        
        externalIPTextField.stringValue = instance.publicDnsName
        externalDNSTextField.stringValue = instance.publicIpAddress
        externalIPTextField.hidden = instance.publicDnsName.isEmpty
        externalIPButton.hidden = instance.publicDnsName.isEmpty
        externalDNSTextField.hidden = instance.publicIpAddress.isEmpty
        externalDNSButton.hidden = instance.publicDnsName.isEmpty
        
        if let pem = instance.pemLocation {
            pemKeyField.stringValue = pem
        } else {
            pemKeyField.stringValue = ""
        }
        
        if let userId = instance.userId{
            userIDField.stringValue = userId
        } else {
            userIDField.stringValue = ""
        }
    }
}

class InstanceConsoleViewController : InstanceTabViewController {
    
    @IBOutlet var textView: NSTextView!
    
    override var instance: Instance! {
        didSet {
            if active {
                reloadConsoleForAccount()
            }
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.reloadConsoleForAccount()
    }
    
    func reloadConsoleForAccount(){
        self.textView.string = ""
        self.accountController.fetchConsoleOutput(account, instance: instance) { (error, output) -> Void in
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                if error != nil {
                    presentAWSError(error!)
                } else {
                    self.textView.string = output
                }
            })

        }
    }
    
    @IBAction func refreshConsole(sender: AnyObject) {
        self.reloadConsoleForAccount()
    }
    
}


class InstanceDetailsTabViewController : InstanceTabViewController {
    @IBOutlet weak var instanceIdLabel: NSTextField!
    @IBOutlet weak var availabilityZoneLabel: NSTextField!
    @IBOutlet weak var imageIdLabel: NSTextField!
    @IBOutlet weak var instanceGroupLabel: NSTextField!
    @IBOutlet weak var keyNameLabel: NSTextField!
    @IBOutlet weak var launchTimeLabel: NSTextField!
    @IBOutlet weak var placementGroupLabel: NSTextField!
    @IBOutlet weak var platformLabel: NSTextField!
    @IBOutlet weak var vpcIdLabel: NSTextField!
    @IBOutlet weak var architectureLabel: NSTextField!
        
    lazy var dateTimeFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .MediumStyle
        return formatter
    }()
    
    override var instance: Instance! {
        didSet {
            if active {
                reload()
            }
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        reload()
    }
    
    func reload(){
        instanceIdLabel.placeholderString = instance.instanceId
        availabilityZoneLabel.placeholderString = instance.availabilityZone == nil ? "" : instance.availabilityZone!
        imageIdLabel.placeholderString = instance.imageId == nil ? "" : instance.imageId!
        instanceGroupLabel.placeholderString = instance.instanceGroup == nil ? "" : instance.instanceGroup!
        keyNameLabel.placeholderString = instance.keyName == nil ? "" : instance.keyName!
        launchTimeLabel.placeholderString = instance.launchTime == nil ? "" : dateFormatter.stringFromDate(instance.launchTime!)
        placementGroupLabel.placeholderString = instance.placementGroup == nil ? "" : instance.placementGroup!
        platformLabel.placeholderString = instance.platform == nil ? "" : instance.platform!
        vpcIdLabel.placeholderString = instance.vpcId == nil ? "" : instance.vpcId!
        architectureLabel.placeholderString = instance.architecture == nil ? "" : instance.architecture!
    }

}


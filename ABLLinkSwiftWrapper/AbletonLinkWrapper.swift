//
//  MenuViewController.swift
//  LightRider
//
//  Created by Kevin on 08/02/2017.
//  Copyright © 2017 Lightingsoft. All rights reserved.
//

import UIKit
import SlideMenuControllerSwift
import XHL_XHardwareLibrarySwift
import SDKMobile
import ALLoadingView
import Crashlytics

class MenuViewController: UITableViewController, SlideMenuControllerDelegate, CallBackEnumerate, ProjectManagerDelegate, UITextFieldDelegate, CallBackHotPlug {
	
	let defaultFont = UIFont(name: "Roboto-Medium", size: 16)
	let defaultFontColor = UIColor(colorLiteralRed: 102/255, green: 102/255, blue: 102/255, alpha: 1)
	static var colorForCellUnselected = UIColor(colorLiteralRed: 41/255, green: 41/255, blue: 41/255, alpha: 1)
	static var colorForCellSelected = UIColor(colorLiteralRed: 50/255, green: 50/255, blue: 50/255, alpha: 1)
	
	var appDelegate: AppDelegate? = nil
	var projectNameList: [String] = [String]()
	private var selectedViewId = 0
	private var deleteMode = false
	private var selectedItemToEdit = -1
	private var editingInterface = false
	private var editingProjects = false
	private var interfaceName: String = "Art Net Device"
	private var artNetPort: String = "0"
	private var ipAddressArray: [String] = []
	private var networkMaskArray: [String] = []
	private var firstEnumerate: Bool = true
	private var currentStoredDevice: StoredVirtualDevice = StoredVirtualDevice(interfaceName: "artNet", artNetPort: "7", ipAddressArray: ["192", "168", "1", "125"], networkMaskArray: ["255", "255", "255", "0"])
	
	private var refreshing = true {
		didSet {
			if (!refreshing) {
				DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
					self.appDelegate?.dataRefreshBlocked = self.refreshing
				}
			}
			else {
				self.appDelegate?.dataRefreshBlocked = self.refreshing
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		XHL.libXHW().addCallBackEnumerate(self)
		XHL.libXHW().addCallBackHotPlug(self)
		tableView.rowHeight = UITableViewAutomaticDimension
		tableView.estimatedRowHeight = 140
		appDelegate = UIApplication.shared.delegate as? AppDelegate
		projectNameList = appDelegate!.projectManager.listProjectFile()
		appDelegate?.projectManager.projectManagerDelegateArray.append(self)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK: - Table view data source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		// #warning Incomplete implementation, return the number of sections
		return 5
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete implementation, return the number of rows
		
		switch section {
		case 0:
			return 1
		case 1:
			return 2
		case 2:
			return ((appDelegate?.arrayOfDevices.count) ?? 0) + 2
		case 3:
			return projectNameList.count + 1
		case 4:
			return 1
		default:
			return 0
		}
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		let section = indexPath.section
		switch section {
		case 0:
			return 166
		default:
			return 40
		}
	}
	
	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		if let cell = tableView.dequeueReusableCell(withIdentifier: "titleCell") as? menuTableViewCell {
			cell.backgroundColor = MenuViewController.colorForCellUnselected
			cell.textLabel?.textColor = defaultFontColor
			cell.textLabel?.font = UIFont(name: "Roboto-Medium", size: 12)
			cell.accessoryType = .none
			cell.headerCell = true
			cell.headerId = section
			cell.Button.removeTarget(nil, action: nil, for: .allEvents)
			switch (section) {
			case 0:
				cell.Button.isHidden = true
				cell.Button.setImage(nil, for: .normal)
				cell.textLabel?.text = "Logo";
			case 1:
				cell.Button.isHidden = true
				cell.textLabel?.text = "Mode";
			case 2:
				cell.Button.isHidden = false
				cell.textLabel?.text =  NSLocalizedString("Interfaces", comment: "");
				cell.Button.addTarget(self, action: #selector(cellButtonClicked), for: .touchUpInside)
				if (editingInterface) {
					cell.Button.setImage(#imageLiteral(resourceName: "icon_menu_valid"), for: .normal)
				} else {
					cell.Button.setImage(#imageLiteral(resourceName: "icon_menu_edit"), for: .normal)
				}
			case 4:
				cell.Button.setImage(nil, for: .normal)
				cell.Button.isHidden = true
				cell.textLabel?.text = "Sync"
				break
			default:
				cell.Button.isHidden = false
				cell.textLabel?.text = NSLocalizedString("My Projects", comment: "My Projects");
				cell.Button.addTarget(self, action: #selector(cellButtonClicked), for: .touchUpInside)
				if (editingProjects) {
					cell.Button.setImage(#imageLiteral(resourceName: "icon_menu_valid"), for: .normal)
				} else {
					cell.Button.setImage(#imageLiteral(resourceName: "icon_menu_edit"), for: .normal)
				}
			}
			return cell
		}
		return UIView()
	}
	
	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		switch (section) {
		case 0, 1:
			return 0
		default:
			return 40
		}
	}
	
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		let section = indexPath.section
		let row = indexPath.row
		switch section {
		case 0:
			if let cell = tableView.dequeueReusableCell(withIdentifier: "imageCell") {
				cell.backgroundColor = MenuViewController.colorForCellUnselected
				cell.accessoryType = .none
				cell.accessoryView = nil
				cell.imageView?.tintColor = defaultFontColor
				cell.imageView?.contentMode = .center
				
				return cell
			}
		case 1:
			if let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell") as? menuTableViewCell {
				cell.backgroundColor = MenuViewController.colorForCellUnselected
				cell.accessoryView = nil
				cell.accessoryType = .none
				cell.textLabel?.textColor = defaultFontColor
				cell.textLabel?.font = defaultFont
				cell.imageView?.tintColor = defaultFontColor
				cell.imageView?.contentMode = .center
				cell.Button.removeTarget(nil, action: nil, for: .allEvents)
				cell.Button.isHidden = true
				if (row == selectedViewId)
				{
					cell.backgroundColor = MenuViewController.colorForCellSelected
					cell.textLabel?.textColor = .white
					cell.imageView?.tintColor = .white
				}
				switch row {
				case 0 :
					cell.textLabel?.text = "Live"
					cell.imageView?.image = UIImage(named: "icon_menu_live")
					
				default :
					cell.textLabel?.text = NSLocalizedString("Fixtures", comment: "Settings Screen Name")
					cell.imageView?.image = UIImage(named: "icon_menu_fixture")
					cell.textLabel?.accessibilityIdentifier = "Fixtures"
				}
				return cell
			}
		case 2:
			if let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell") as? menuTableViewCell {
				cell.backgroundColor = MenuViewController.colorForCellUnselected
				cell.textLabel?.textColor = defaultFontColor
				cell.imageView?.tintColor = defaultFontColor
				cell.imageView?.contentMode = .center
				cell.accessoryView = nil
				cell.Button.removeTarget(nil, action: nil, for: .allEvents)
				cell.Button.isHidden = true
				if (row < appDelegate?.arrayOfDevices.count ?? 0){
					if let device = appDelegate?.arrayOfDevices[row] {
						cell.textLabel?.text = device.getDeviceName()
						if (device.getInterface(XHL_IT_VirtualArtNet) as? XHL_VirtualArtNetInterface) != nil {
							if (editingInterface) {
								cell.Button.isHidden = false
								cell.Button.setImage(#imageLiteral(resourceName: "icon_menu_edit"), for: .normal)
								cell.Button.addTarget(self, action: #selector(cellButtonClicked), for: .touchUpInside)
							}
							cell.imageView?.image = #imageLiteral(resourceName: "icon_menu_artnet")
						}
						else {
							cell.imageView?.image = UIImage(named: "icon_menu_interface")
						}
						if (device.isOpen() == true)
						{
							cell.backgroundColor = MenuViewController.colorForCellSelected
							cell.accessoryType = .checkmark
							cell.tintColor = .cyan
							cell.imageView?.tintColor = .white
						}
						else {
							cell.accessoryType = .none
						}
					}
				}
				else if (row == appDelegate?.arrayOfDevices.count) {
					cell.imageView?.image = UIImage(named: "icon_menu_refresh")
					if (refreshing == true) {
						cell.textLabel?.text = NSLocalizedString("Loading...", comment: "Menu Loading")
						cell.imageView?.startRotating()
					}
					else {
						cell.textLabel?.text = NSLocalizedString("Refresh...", comment: "Menu Refresh")
						cell.imageView?.stopRotating()
					}
				}
				else {
					cell.textLabel?.text = NSLocalizedString("Create a Virtual Device", comment: "Menu Create a Virtual Device")
					cell.imageView?.image = UIImage(named: "icon_menu_add")
				}
				return cell
			}
		case 3:
			if let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell") as? menuTableViewCell {
				cell.imageView?.contentMode = .center
				cell.accessoryView = nil
				cell.accessoryType = .none
				cell.backgroundColor = MenuViewController.colorForCellUnselected
				cell.textLabel?.textColor = defaultFontColor
				cell.textLabel?.font = defaultFont
				cell.imageView?.tintColor = defaultFontColor
				cell.Button.removeTarget(nil, action: nil, for: .allEvents)
				cell.Button.isHidden = true
				if (row == projectNameList.count) {
					cell.textLabel?.text = NSLocalizedString("Create a Project", comment: "Menu Create a Project")
					cell.imageView?.image = UIImage(named: "icon_menu_add")
				}
				else {
					if (appDelegate!.CURRENT_PROJECT_NAME == projectNameList[row]) {
						cell.backgroundColor = MenuViewController.colorForCellSelected
						cell.textLabel?.textColor = .white
						cell.imageView?.tintColor = .white
					}
					cell.textLabel?.text = projectNameList[row]
					cell.imageView?.image = UIImage(named: "icon_menu_project")
					if (editingProjects)
					{
						cell.Button.isHidden = false
						cell.Button.setImage(#imageLiteral(resourceName: "icon_menu_edit"), for: .normal)
						cell.Button.addTarget(self, action: #selector(cellButtonClicked), for: .touchUpInside)
					}
				}
				return cell
			}
		case 4:
			if let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell") {
				
				cell.backgroundColor = MenuViewController.colorForCellUnselected
				cell.accessoryView = nil
				cell.accessoryType = .none
				cell.textLabel?.textColor = defaultFontColor
				cell.textLabel?.font = defaultFont
				cell.imageView?.tintColor = defaultFontColor
				cell.imageView?.image = nil
				switch row {
				case 0 :
					cell.textLabel?.text = "Ableton Link"
					cell.detailTextLabel?.text = (AbletonLinkWrapper.sharedInstance.isEnabled) ? "Enabled" : "Disabled"
					break
				default :
					break
				}
				return cell
			}
		default:
			if let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell") {
				cell.accessoryView = nil
				cell.imageView?.tintColor = defaultFontColor
				return cell
			}
		}
		return UITableViewCell()
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		let row = indexPath.row
		let section = indexPath.section
		//super.tableView(tableView, didSelectRowAt: indexPath)
		switch section  {
		case 1:
			if let controller = self.slideMenuController()?.mainViewController as? UINavigationController {
				selectedViewId = row
				switch row {
				case 0:
					if (controller.topViewController is FixtureSettingsViewController)
					{
						controller.popToRootViewController(animated: true)
						self.slideMenuController()?.closeLeft()
					}
				case 1:
					if (controller.topViewController is LiveViewController)
					{
						controller.topViewController?.performSegue(withIdentifier: "showSettings", sender: controller.topViewController)
						self.slideMenuController()?.closeLeft()
					}
				default:
					break
				}
			}
		case 2:
			if (row == appDelegate?.arrayOfDevices.count) {
				if (!refreshing) {
					self.appDelegate?.arrayOfDevices.removeAll()
					self.refreshing = true
					self.tableView.reloadData()
					DispatchQueue(label: "enumate").async {
						_ = XHL.libXHW().enumerate(true, FirmwareTooRecent: true, WrongDongle: true)
					}
				}
			}
			else if (row == appDelegate!.arrayOfDevices.count + 1) {
				openVirtualDeviceModal()
			}
			else {
				if let device = appDelegate?.arrayOfDevices[row] {
					if (device.isOpen() == true)
					{
						#if DEBUG
							print("Close Device Connection")
						#else
							Answers.logCustomEvent(withName: "Close Device Connection",
							                       customAttributes: ["Device Name" : device.getDeviceName() ?? "Device",
							                                          "Device Type": device.getDeviceTypeName()])
						#endif
						device.close()
					} else {
						#if DEBUG
							print("Open Device Connection")
						#else
							Answers.logCustomEvent(withName: "Open Device Connection",
							                       customAttributes: ["Device Name" : device.getDeviceName() ?? "Device",
							                                          "Device Type": device.getDeviceTypeName()])
						#endif
						
						if (device.open() == false) {
							let error = XHL.libXHW().getLastErrorDescription()
							#if DEBUG
								print("Error During Device Connection")
							#else
								Answers.logCustomEvent(withName: "Error During Device Connection",
								                       customAttributes: ["Device Name" : device.getDeviceName() ?? "Device",
								                                          "Device Type": device.getDeviceTypeName(),
								                                          "Error" : error])
							#endif
							
							if (error == "[XHL]The devices firmware is too old: update the device firmware") {
								errorPopUp(title: NSLocalizedString("Error : Firmware Too Old", comment: "PopUp Error Firmware too Old Title"), message:  NSLocalizedString("Please update your devices firmware using the hardware manager available from our website.", comment: "PopUp Error Firmware too Old Message"))
							}
							else {
								errorPopUp(title: NSLocalizedString("Error", comment: "Basic Error Opop Title"), message:  NSLocalizedString("Could Not open device : Unknown Error", comment: "Basic Error popup message device connection"))
							}
						}
					}
				}
				self.tableView.reloadData()
			}
		case 3:
			if (row == projectNameList.count) {
				openNewProjectModal()
				self.tableView.deselectRow(at: indexPath, animated: true)
			}
			else {
				self.appDelegate?.projectManager.loadProjectFile(projectNameList[row])
			}
		case 4:
			switch row {
			case 0:
				let link = AbletonLinkWrapper.sharedInstance
				if let vc = link.getViewController() {
					if let controller = self.slideMenuController()?.mainViewController as? UINavigationController {
						controller.setNavigationBarHidden(false, animated: false)
						controller.pushViewController(vc, animated: true)
						self.slideMenuController()?.closeLeft()
					}
				}
			default:
				break
			}
		default:
			#if DEBUG
				let alert = UIAlertController(title: "SET DEV IP 3D", message: "DEBUG ONLY", preferredStyle: UIAlertControllerStyle.alert)
				alert.addTextField { (textField) in
					textField.text = self.appDelegate?.devIp
				}
				alert.addAction(UIAlertAction(title: NSLocalizedString("Change", comment: ""), style: .cancel, handler: { [weak alert] (_) in
					self.appDelegate?.setDevIP(ip: alert?.textFields?[0].text ?? "192.168.1.1")
				}))
				
				alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: nil))
				self.present(alert, animated: true, completion: nil)
				
			#endif
			break
		}
		
	}
	
	override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		let cellToDeSelect:UITableViewCell = tableView.cellForRow(at: indexPath)!
		cellToDeSelect.contentView.backgroundColor = MenuViewController.colorForCellUnselected
	}
	
	func cellButtonClicked(sender: UIButton) {
		if let cell = sender.superview?.superview as? menuTableViewCell {
			if cell.headerCell {
				switch cell.headerId {
				case 2:
					self.editingInterface = !self.editingInterface
					self.tableView.reloadData()
				case 3:
					self.editingProjects = !self.editingProjects
					self.tableView.reloadData()
				default:
					return
				}
			} else if let path = self.tableView.indexPath(for: cell) {
				var message = ""
				if (path.section == 2) {
					message = NSLocalizedString("Edit your Virtual Interface :", comment: "in menu, when user want to delete or rename interface")
				} else {
					message = NSLocalizedString("Edit your Project :", comment: "in menu, when user want to delete or rename project")
				}
				let optionMenu = UIAlertController(title: message, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
				selectedItemToEdit = path.row
				let EditTitle = NSLocalizedString("Edit", comment: "")
				let option1 = UIAlertAction(title: ((path.section == 2) ? EditTitle : NSLocalizedString("Rename", comment: "")), style: .default, handler: {
					
					(alert: UIAlertAction!) -> Void in
					if (path.section == 2) {
						self.editInterface()
					}
					if (path.section == 3) {
						self.renameProject()
					}
				})
				
				let option2 = UIAlertAction(title: NSLocalizedString("DELETE", comment: ""), style: .destructive, handler: {
					
					(alert: UIAlertAction!) -> Void in
					if (path.section == 2) {
						
						self.openDeleteInterfaceModal()
					}
					if (path.section == 3) {
						
						self.openDeleteProjectModal()
					}
					
				})
				
				optionMenu.addAction(option1)
				optionMenu.addAction(option2)
				
				if let currentPopoverpresentioncontroller = optionMenu.popoverPresentationController{
					currentPopoverpresentioncontroller.sourceView = cell.Button
					currentPopoverpresentioncontroller.sourceRect = cell.Button.bounds
					currentPopoverpresentioncontroller.permittedArrowDirections = UIPopoverArrowDirection.left
					self.present(optionMenu, animated: true, completion: nil)
				} else {
					print("no Path")
				}
			}
		}
	}
	
	func openNewProjectModal() {
		let alert = UIAlertController(title: NSLocalizedString("New Project", comment: ""), message: NSLocalizedString("Name Your Project", comment: ""), preferredStyle: .alert)
		
		alert.addTextField { (textField) in
			textField.text = "MyProject"
		}
		
		alert.addAction(UIAlertAction(title: NSLocalizedString("Keep current fixtures", comment: ""), style: .default, handler: { [weak alert] (_) in
			self.openKeepPresetsModal(keepFixtures: true, newProjectAlert: alert!)
		}))
		
		
		alert.addAction(UIAlertAction(title: NSLocalizedString("Do not keep current fixtures", comment: ""), style: .default, handler: { [weak alert] (_) in
			self.openKeepPresetsModal(keepFixtures: false, newProjectAlert: alert!)
		}))
		
		alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
		
		self.present(alert, animated: true, completion: nil)
	}
	
	func openKeepPresetsModal(keepFixtures: Bool, newProjectAlert: UIAlertController) {
		let alert = UIAlertController(title: NSLocalizedString("Keep Presets", comment: ""), message: NSLocalizedString("Would you like to keep the current presets?", comment: ""), preferredStyle: .alert)
		
		alert.addAction(UIAlertAction(title: NSLocalizedString("Keep current presets", comment: ""), style: .default, handler: {(_) in
			self.createNewProject(alert: newProjectAlert, keepFixtures: keepFixtures, keepPresets: true)
		}))
		
		
		alert.addAction(UIAlertAction(title: NSLocalizedString("Do not keep current presets", comment: ""), style: .default, handler: {(_) in
			self.createNewProject(alert: newProjectAlert, keepFixtures: keepFixtures, keepPresets: false)
		}))
		
		alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
		
		self.present(alert, animated: true, completion: nil)
	}
	
	func createNewProject(alert: UIAlertController, keepFixtures: Bool, keepPresets: Bool){
		let textField = alert.textFields![0]
		if (textField.text != ""){
			if(!projectNameList.contains(textField.text!)){
				if(!keepFixtures){
					appDelegate?.mColorEffect.mListControllers.removeAll()
					appDelegate?.mMoveEffect.mListControllers.removeAll()
					for fixture in Fixture.getFixtures(){
						for controller in fixture.getControllers(){
							controller.setValue(0)
						}
						for channel in fixture.getListChannel(){
							channel.setValue(value: 0)
						}
					}
					
					for theFixture in Fixture.getFixtures(){
						theFixture.delete()
					}
				}
				
				ProjectManager.keepPresets = keepPresets
				_ = self.appDelegate?.projectManager.createProjectFile((textField.text)!)
				self.appDelegate?.projectManager.openedProject = textField.text!
				self.appDelegate?.projectManager.saveProjectFile()
				self.projectNameList = self.appDelegate!.projectManager.listProjectFile()
				self.tableView.reloadData()
			} else{
				newProjectNameError(errorText: "Project already exists!")
			}
		} else{
			newProjectNameError(errorText: "Please enter a project name!")
		}
	}
	
	func renameProject() {
		let project = projectNameList[selectedItemToEdit]
		let alert = UIAlertController(title: NSLocalizedString("Rename ", comment: "") + project, message: NSLocalizedString("Rename Your Project", comment: ""), preferredStyle: .alert)
		
		alert.addTextField { (textField) in
			textField.text = project
		}
		
		alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { [weak alert] (_) in
			
			let appFolder: File = AppFile().createProjectFolder(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/DJApp")
			
			let fileToRename: File = File(pathName: appFolder.getPath() + "/" + (project) + ".dlm")
			let newName = alert?.textFields?[0].text ?? "My Project"
			if (fileToRename.rename(newName + ".dlm")) {
				if (project == self.appDelegate?.CURRENT_PROJECT_NAME) {
					self.appDelegate?.CURRENT_PROJECT_NAME = newName
					ProjectManager.writeLatestProjectName(latestProjectName: newName)
				}
				self.projectNameList = self.appDelegate?.projectManager.listProjectFile() ?? [String]()
				self.tableView.reloadData()
			}
		}))
		alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
		self.present(alert, animated: true, completion: nil)
		
	}
	
	func editInterface() {
		if let device = appDelegate?.arrayOfDevices[selectedItemToEdit] {
			if (device.getInterface(XHL_IT_VirtualArtNet) as? XHL_VirtualArtNetInterface) != nil {
				let defaults = UserDefaults.standard
				var devices: [StoredVirtualDevice] = []
				let deviceData: Data = (defaults.object(forKey: "VirtualDevices") as? Data)!
				
				let devices2 = NSKeyedUnarchiver.unarchiveObject(with: deviceData) as? [Any]
				for device in devices2!{
					if let aDevice: StoredVirtualDevice = device as? StoredVirtualDevice{
						devices.append(aDevice)
					}
				}
				
				if(devices.count > 0){
					for i in 0..<devices.count{
						currentStoredDevice = devices[i]
						if(currentStoredDevice.interfaceName == device.getDeviceName()){
							self.openVirtualDeviceModal(editInstead: true)
							return
						}
					}
				}
			}
		}
	}
	
	
	func openVirtualDeviceModal(editInstead: Bool = false)
	{
		let alert = UIAlertController(title: NSLocalizedString((editInstead ? "Edit Virtual Device" : "Create Virtual Device"), comment: ""), message: "", preferredStyle: .alert)
		
		let name = currentStoredDevice.interfaceName
		let ipAddress = String((currentStoredDevice.ipAddressArray[0])) + "." + (currentStoredDevice.ipAddressArray[1]) + "." +  String((currentStoredDevice.ipAddressArray[2])) + "."  + String((currentStoredDevice.ipAddressArray[3]))
		let networkMask = "\(currentStoredDevice.networkMaskArray[0]).\(currentStoredDevice.networkMaskArray[1]).\(currentStoredDevice.networkMaskArray[2]).\(currentStoredDevice.networkMaskArray[3])"
		
		alert.addTextField { (textField) in
			textField.keyboardType = .asciiCapable
			//textField.borderStyle = .roundedRect
			textField.placeholder = NSLocalizedString("Device Name", comment: "")
			textField.text = name
		}
		
		alert.addTextField { (textField) in
			textField.delegate = self
			textField.keyboardType = .numberPad
			textField.placeholder = NSLocalizedString("IP Address", comment: "")
			//textField.borderStyle = .roundedRect
			textField.background = nil
			textField.backgroundColor = UIColor.clear
			textField.text = ipAddress
			
		}
		
		alert.addTextField { (textField) in
			// textField.delegate = self
			textField.keyboardType = .numberPad
			//textField.borderStyle = .roundedRect
			textField.placeholder = NSLocalizedString("Network Mask", comment: "")
			textField.text = networkMask
			textField.delegate = self
		}
		
		alert.addTextField { (textField) in
			textField.keyboardType = .numberPad
			//textField.borderStyle = .roundedRect
			textField.placeholder = NSLocalizedString("Art-Net Port", comment: "")
			textField.delegate = self
			textField.text = self.currentStoredDevice.artNetPort
		}
		
		
		alert.addAction(UIAlertAction(title: NSLocalizedString((editInstead ? "Edit" : "Create"), comment: ""), style: .cancel, handler: { [weak alert] (_) in
			self.validateVirtualDevice(alert: alert!, editInstead: editInstead)
		}))
		
		alert.modalPresentationStyle = .formSheet
		alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: nil))
		
		self.present(alert, animated: true, completion: nil)
		
	}
	
	
	
	func deviceNameExists(deviceName: String) -> Bool{
		let defaults = UserDefaults.standard
		var devices: [StoredVirtualDevice] = []
		if let deviceData = defaults.object(forKey: "VirtualDevices") as? Data {
			if let devices2 = NSKeyedUnarchiver.unarchiveObject(with: deviceData) as? [Any]{
				if(devices2.count > 0){
					for device in devices2{
						if let aDevice: StoredVirtualDevice = device as? StoredVirtualDevice{
							devices.append(aDevice)
						}
					}
				}
			}
		}
		
		for device in devices{
			if(device.interfaceName == deviceName){
				return true
			}
		}
		
		return false
	}
	
	func validateVirtualDevice(alert: UIAlertController, editInstead: Bool = false){
		ipAddressArray = []
		networkMaskArray = []
		
		interfaceName = alert.textFields![0].text!
		var ipAddress = alert.textFields![1].text!
		var networkMask = alert.textFields![2].text!
		artNetPort = alert.textFields![3].text!
		
		if(deviceNameExists(deviceName: interfaceName)){
			if (!editInstead || appDelegate?.arrayOfDevices[selectedItemToEdit].getDeviceName() != interfaceName) {
				virtualDeviceErrorAlert(virtualDeviceAlert: alert, errorTitle: NSLocalizedString("Device Name Already Exists!", comment: ""), errorMessage: NSLocalizedString("Please enter an alternative name", comment: ""))
				return
			}
		}
		
		for _ in 0...2{
			
			if (ipAddress.contains(".")){
				if (networkMask.contains(".")){
					var start = ipAddress.startIndex
					var end = ipAddress.indexOf(".")
					var endWithOffset = ipAddress.index(end!, offsetBy: 1)
					ipAddressArray.append((ipAddress.substring(with: start..<end!)))
					ipAddress.removeSubrange(start..<endWithOffset)
					start = networkMask.startIndex
					end = networkMask.indexOf(".")
					endWithOffset = networkMask.index(end!, offsetBy: 1)
					networkMaskArray.append((networkMask.substring(with: start..<end!)))
					networkMask.removeSubrange(start..<endWithOffset)
				} else{
					virtualDeviceErrorAlert(virtualDeviceAlert: alert, errorTitle: NSLocalizedString("Incorrect Network Mask format!", comment: ""), errorMessage: NSLocalizedString("Please enter Network Mask in the correct format", comment: ""))
					return
				}
			} else{
				virtualDeviceErrorAlert(virtualDeviceAlert: alert, errorTitle: NSLocalizedString("Incorrect IP Address format!", comment: ""), errorMessage: NSLocalizedString("Please enter IP Address in the correct format", comment: ""))
				return
			}
			
		}
		
		ipAddressArray.append(ipAddress)
		networkMaskArray.append(networkMask)
		
		for field in ipAddressArray{
			if(Int(field)! < 0 || Int(field)! > 255){
				virtualDeviceErrorAlert(virtualDeviceAlert: alert, errorTitle: NSLocalizedString("Incorrect IP Address format!", comment: ""), errorMessage: NSLocalizedString("Values should be between 0 and 255", comment: ""))
				return
			}
		}
		
		for field in networkMaskArray{
			if(Int(field)! < 0 || Int(field)! > 255){
				virtualDeviceErrorAlert(virtualDeviceAlert: alert, errorTitle: NSLocalizedString("Incorrect Network Mask format!", comment: ""), errorMessage: NSLocalizedString("Values should be between 0 and 255", comment: ""))
				return
			}
		}
		
		if(artNetPort.characters.count == 0){
			virtualDeviceErrorAlert(virtualDeviceAlert: alert, errorTitle: NSLocalizedString("Incorrect Art-Net Port", comment: ""), errorMessage: NSLocalizedString("Please enter an Art Net port", comment: ""))
			return
		}
		
		if(Int(artNetPort) == nil){
			virtualDeviceErrorAlert(virtualDeviceAlert: alert, errorTitle: NSLocalizedString("Incorrect Art-Net Port", comment: ""), errorMessage: NSLocalizedString("Art Net port must be an integer", comment: ""))
			return
		}
		
		if(Int(artNetPort)! >= 0 && Int(artNetPort)! <= 32767){
		} else{
			virtualDeviceErrorAlert(virtualDeviceAlert: alert, errorTitle: NSLocalizedString("Incorrect Art-Net Port", comment: ""), errorMessage: NSLocalizedString("Please enter an art net port within the range 0 - 32,767", comment: ""))
			return
		}
		
		let defaults = UserDefaults.standard
		var devices: [StoredVirtualDevice] = []
		if let deviceData  = defaults.object(forKey: "VirtualDevices") as? Data{
			if let newDevices = NSKeyedUnarchiver.unarchiveObject(with: deviceData)  as? [StoredVirtualDevice] {
				devices = newDevices
			}
		}
		
		if (editInstead) {
			editVirtualDevice(ipAddressArray: ipAddressArray, networkMaskArray: networkMaskArray, artNetPort: artNetPort, interfaceName: interfaceName)
		} else {
			
			if(devices.count > 0){
				for i in 0..<devices.count{
					if (devices[i].ipAddressArray[0] == ipAddressArray[0] &&
						devices[i].ipAddressArray[1] == ipAddressArray[1] &&
						devices[i].ipAddressArray[2] == ipAddressArray[2] &&
						devices[i].ipAddressArray[3] == ipAddressArray[3]) {
						virtualDeviceErrorAlert(virtualDeviceAlert: alert, errorTitle: NSLocalizedString("IP Address In Use", comment: ""), errorMessage: NSLocalizedString("IP Address already in use. Please select another.", comment: ""))
						return
					}
				}
			}
			createVirtualDevice(ipAddressArray: ipAddressArray, networkMaskArray: networkMaskArray)
		}
	}
	
	func editVirtualDevice(ipAddressArray: [String], networkMaskArray: [String], artNetPort: String, interfaceName: String) {
		if let device = self.appDelegate?.arrayOfDevices[self.selectedItemToEdit] {
			let defaults = UserDefaults.standard
			let deviceData: Data = (defaults.object(forKey: "VirtualDevices") as? Data)!
			let devices = NSKeyedUnarchiver.unarchiveObject(with: deviceData) as? [Any]
			if let theDeviceArray: [StoredVirtualDevice] = devices as? [StoredVirtualDevice]{
				var i = 0
				for device in theDeviceArray{
					if device.interfaceName == currentStoredDevice.interfaceName{
						theDeviceArray[i].ipAddressArray = ipAddressArray
						theDeviceArray[i].networkMaskArray = networkMaskArray
						theDeviceArray[i].interfaceName = interfaceName
						theDeviceArray[i].artNetPort = artNetPort
						currentStoredDevice = theDeviceArray[i]
					}
					i+=1
				}
				let encodedDeviceData: Data = NSKeyedArchiver.archivedData(withRootObject: theDeviceArray)
				defaults.set(encodedDeviceData, forKey: "VirtualDevices")
				defaults.synchronize()
				
				
				let ethernetInterface: XHL_EthernetInterface = device.getInterface(XHL_IT_Ethernet)! as! XHL_EthernetInterface
				let ipAddress = XHL_HostAddress(ip0: UInt(ipAddressArray[0]) ?? 192, ip1: UInt(ipAddressArray[1]) ?? 168, ip2: UInt(ipAddressArray[2]) ?? 0, ip3: UInt(ipAddressArray[3]) ?? 0)
				let networkMask = XHL_HostAddress(ip0: UInt(networkMaskArray[0]) ?? 192, ip1: UInt(networkMaskArray[1]) ?? 168, ip2: UInt(networkMaskArray[2]) ?? 0, ip3: UInt(networkMaskArray[3]) ?? 0)
				
				let artNetInterface: XHL_ArtNetInterface = device.getInterface(XHL_IT_ArtNet)! as! XHL_ArtNetInterface
				_ = artNetInterface.setLongName(aName: interfaceName)
				_ = artNetInterface.setShortName(aName: interfaceName)
				
				// gateway is irrelevant for art net
				_ = ethernetInterface.setIpConf(hasEthernetEnabled: true, hasDhcpEnable: true, addressHandle: ipAddress, maskHandle: networkMask, gatewayHandle: networkMask)
				tableView.reloadData()
				refreshXHLDevices()
				
			}
			
		}
	}
	
	func createVirtualDevice(ipAddressArray: [String], networkMaskArray: [String]){
		
		let busConfiguration = XHL.libXHW().getBusConfiguration(XHL_BT_Artnet)
		if let artNetBus = busConfiguration as? XHL_ArtNetBusConfiguration {
			let host = XHL_HostAddress(ip0: UInt(ipAddressArray[0]) ?? 192, ip1: UInt(ipAddressArray[1]) ?? 168, ip2: UInt(ipAddressArray[2])  ?? 0, ip3: UInt(ipAddressArray[3]) ?? 0)
			let network = XHL_HostAddress(ip0: UInt(networkMaskArray[0]) ?? 255, ip1: UInt(networkMaskArray[1]) ?? 255, ip2: UInt(networkMaskArray[2])  ?? 0, ip3: UInt(networkMaskArray[3]) ?? 0)
			
			let device = artNetBus.addVirtualDevice(aAddress: host, aNetworkMask: network)
			if let interface = device.getInterface(XHL_IT_VirtualArtNet) as? XHL_VirtualArtNetInterface {
				
				if (interface.addNewPort(type: DMX512Type, input: false, portInAddress: 0, output: true, portOutAddress: UInt(artNetPort ) ?? 0) != 0) {
					
					Answers.logCustomEvent(withName: "Create A Virtual Device",
					                       customAttributes: [:])
				}
				
				_ = interface.setShortName(aName: interfaceName )
				_ = device.open()
				if (!refreshing) {
					self.appDelegate?.arrayOfDevices.removeAll()
					self.refreshing = true
					self.tableView.reloadData()
					DispatchQueue(label: "enumate").async {
						_ = XHL.libXHW().enumerate(true, FirmwareTooRecent: true, WrongDongle: true)
					}
				}
				storeVirtualDevice()
			}
		}
		
	}
	
	func virtualDeviceErrorAlert(virtualDeviceAlert: UIAlertController, errorTitle: String, errorMessage: String){
		let alert = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler:  { (complete) in
			self.openVirtualDeviceModal()
		}))
		self.present(alert, animated: true, completion: nil)
	}
	
	
	func newProjectNameError(errorText: String){
		let alert = UIAlertController(title: NSLocalizedString(errorText, comment: ""), message: "", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler:  { (complete) in
			self.openNewProjectModal()
		}))
		self.present(alert, animated: true, completion: nil)
	}
	
	func errorPopUpCreateVirtualDevice(title: String, message : String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: {
			void in
			self.openVirtualDeviceModal()
		}))
		self.present(alert, animated: true, completion: nil)
	}
	
	func errorPopUp(title: String, message : String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: nil))
		self.present(alert, animated: true, completion: nil)
	}
	
	func openDeleteProjectModal() {
		let alert = UIAlertController(title: NSLocalizedString("Delete Project", comment: "Delete PopUp"), message: String(format: NSLocalizedString("Are you sure you want to delete %@", comment: "Confirmation of deletion of project %@"), projectNameList[selectedItemToEdit]), preferredStyle: .alert)
		
		alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel PopUp"), style: .cancel, handler: nil))
		
		alert.addAction(UIAlertAction(title: NSLocalizedString("DELETE", comment: "Confirm Deletion PopUp"), style: .destructive, handler: { void in
			_ = self.appDelegate?.projectManager.deleteProjectFile(fileName: self.projectNameList[self.selectedItemToEdit])
			self.projectNameList.remove(at: self.selectedItemToEdit)
			self.tableView.reloadData()
		}))
		self.present(alert, animated: true, completion: nil)
	}
	
	func openDeleteInterfaceModal() {
		if let device = self.appDelegate?.arrayOfDevices[self.selectedItemToEdit] {
			let alert = UIAlertController(title: NSLocalizedString("Delete Interface", comment: "Delete PopUp"), message: String(format: NSLocalizedString("Are you sure you want to delete %@", comment: "Confirmation of deletion of Interface %@"), device.getDeviceName() ?? "Device"), preferredStyle: .alert)
			
			alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel PopUp"), style: .cancel, handler: nil))
			
			alert.addAction(UIAlertAction(title: NSLocalizedString("DELETE", comment: "Confirm Deletion PopUp"), style: .destructive, handler: { void in
				let busConfiguration = XHL.libXHW().getBusConfiguration(XHL_BT_Artnet)
				if let artNetBus = busConfiguration as? XHL_ArtNetBusConfiguration {
					self.deleteStoredVirtualDevice(deviceName: device.getDeviceName()!)
					self.appDelegate?.arrayOfDevices.remove(at: self.selectedItemToEdit)
					device.removeDeviceStateChangeListener(self.appDelegate!)
					artNetBus.removeVirtualDevice(aDevice: device)
					
				}
				
			}))
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	func leftWillOpen() {
		self.slideMenuController()?.addLeftGestures()
		self.tableView.reloadData()
	}
	
	func leftDidClose() {
		self.slideMenuController()?.removeLeftGestures()
	}
	
	func onBusError(_ busType: XHL_BusType, errorCode: XHL_ErrorCode){
		
	}
	
	func onDeviceFound (_ busType: XHL_BusType, supportState: XHL_SupportState, name: String, description: String) {
		
	}
	
	func deleteStoredVirtualDevice(deviceName: String){
		let defaults: UserDefaults = UserDefaults.standard
		var devices: [StoredVirtualDevice] = []
		
		let deviceData: Data = (defaults.object(forKey: "VirtualDevices") as? Data)!
		let devices2 = NSKeyedUnarchiver.unarchiveObject(with: deviceData) as? [Any]
		
		for device in devices2!{
			if let aDevice: StoredVirtualDevice = device as? StoredVirtualDevice{
				devices.append(aDevice)
			}
		}
		
		if(devices.count > 0){
			for i in 0..<devices.count{
				if(devices[i].interfaceName == deviceName){
					devices.remove(at: i)
					break
				}
			}
		}
		
		if devices.count != 0 {
			let encodedDeviceData: Data = NSKeyedArchiver.archivedData(withRootObject: devices)
			defaults.set(encodedDeviceData, forKey: "VirtualDevices")
		} else {
			defaults.set(nil, forKey: "VirtualDevices")
		}
		defaults.synchronize()
		
	}
	
	func onEndEnumerate(_ errorCode: XHL_ErrorCode?) {
		let defaults = UserDefaults.standard
		var devices: [StoredVirtualDevice] = []
		if let deviceData  = defaults.object(forKey: "VirtualDevices") as? Data{
			if let newDevices = NSKeyedUnarchiver.unarchiveObject(with: deviceData) as? [StoredVirtualDevice] {
				devices.append(contentsOf: newDevices)
			}
		}
		
		if(firstEnumerate){
			if(devices.count > 0){
				for i in 0...devices.count - 1{
					ipAddressArray = devices[i].ipAddressArray
					networkMaskArray = devices[i].networkMaskArray
					interfaceName = devices[i].interfaceName
					artNetPort = devices[i].artNetPort
					createVirtualDevice(ipAddressArray: ipAddressArray, networkMaskArray: networkMaskArray)
				}
			}
			firstEnumerate = false
		}
		
		appDelegate?.arrayOfDevices.removeAll()
		
		refreshXHLDevices()
		
		DispatchQueue.main.async {
			self.refreshing = false
			self.tableView.reloadData()
		}
	}
	
	func refreshXHLDevices(){
		appDelegate?.arrayOfDevices.removeAll()
		if(XHL.libXHW().getDeviceCount() > 0){
			for i in 0...(XHL.libXHW().getDeviceCount() - 1) {
				let device = XHL.libXHW().getDevice(Int32(i))
				
				device.addDeviceStateChangeListener((appDelegate)!)
				appDelegate?.arrayOfDevices.append(device)
			}
		}
	}
	
	func storeVirtualDevice(){
		let defaults = UserDefaults.standard
		var devices: [StoredVirtualDevice] = []
		if let deviceData  = defaults.object(forKey: "VirtualDevices") as? Data{
			if let newDevices = NSKeyedUnarchiver.unarchiveObject(with: deviceData)  as? [StoredVirtualDevice] {
				devices = newDevices
			}
		}
		
		for device in devices{
			if device.interfaceName == interfaceName {
				return
			}
		}
		
		let storedVirtualDevice: StoredVirtualDevice = StoredVirtualDevice(interfaceName: interfaceName, artNetPort: artNetPort, ipAddressArray: ipAddressArray, networkMaskArray: networkMaskArray)
		devices.append(storedVirtualDevice)
		let encodedDeviceData: Data = NSKeyedArchiver.archivedData(withRootObject: devices)
		defaults.set(encodedDeviceData, forKey: "VirtualDevices")
		defaults.synchronize()
	}
	
	func projectHasBeenSaved() {
		projectNameList = appDelegate!.projectManager.listProjectFile()
		DispatchQueue.main.async {
			self.tableView.reloadData()
		}
	}
	
	func projectFailedToSave() {
		projectNameList = appDelegate!.projectManager.listProjectFile()
	}
	
	func projectLoaded() {
		DispatchQueue.main.async {
			self.tableView.reloadData()
		}
	}
	
	func projectCreated() {
		DispatchQueue.main.async {
			self.tableView.reloadData()
		}
	}
	
	func wipOnProject() {
	}
	
	func projectFailedToLoad() {
		
	}
	
	func validateIpAddress(ipToValidate: String) -> Bool {
		
		var sin = sockaddr_in()
		
		if ipToValidate.withCString({ cstring in inet_pton(AF_INET, cstring, &sin.sin_addr) }) == 1 {
			// IPv4 peer.
			return true
		}
		return false;
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "addVirtualDeviceSegue"? :
			let vc = segue.destination
			vc.preferredContentSize = CGSize(width: 350, height: 350)
		default:
			break
		}
	}
	
	// MARK: -
	// MARK: Textfield delegate methods
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool{
		
		if Int(string) != nil {
			return true
		} else {
			if( string == "" || string == "."){
				return true
			} else{
				return false
			}
		}
		
	}
	
	func onDeviceArrival(_ device: XHL_Device, supportState: XHL_SupportState, busType: XHL_BusType, name: String, description: String) -> Bool{
		
		return true
	}
	
	func onDeviceLeft(_ device: XHL_Device, busType: XHL_BusType) -> Bool{
		
		return true
	}
	
	func onDeviceListChanged(){
		self.tableView.reloadData()
	}
	
	
}

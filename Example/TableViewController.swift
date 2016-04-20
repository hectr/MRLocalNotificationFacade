
import UIKit

class TableViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var bodyTextField: UITextField!
    @IBOutlet var actionTextField: UITextField!
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var repeatSwitch: UISwitch!
    @IBOutlet var soundSwitch: UISwitch!
    @IBOutlet var badgeTextField: UITextField!
    @IBOutlet var defaultContextSwitch: UISwitch!
    @IBOutlet var minimalContextSwitch: UISwitch!
    
    let notificationFacade = MRLocalNotificationFacade.defaultInstance()
    
    @IBAction func createNotificationAction(sender: AnyObject) {
        var category: String?
        if (defaultContextSwitch.on) {
            if (minimalContextSwitch.on) {
                category = "all"
            } else {
                category = "default"
            }
        } else {
            if (minimalContextSwitch.on) {
                category = "minimal"
            } else {
                category = nil
            }
        }
        let notification = notificationFacade.buildNotificationWithDate(datePicker.date, timeZone: false, category: category, userInfo: nil)
        notificationFacade.customizeNotificationAlert(notification, title: titleTextField.text, body: bodyTextField.text, action: actionTextField.text, launchImage: nil)
        if (repeatSwitch.on) {
            notificationFacade.customizeNotificationRepeat(notification, interval: NSCalendarUnit.Day)
        }
        if let badgeString = badgeTextField.text {
            if let badge = Int(badgeString) {
                notificationFacade.customizeNotification(notification, appIconBadge: badge, sound: soundSwitch.on)
            }
        }
        var valid: Bool = true
        do {
            try notificationFacade.scheduleNotification(notification)
        }
        catch {
            valid = false
            let alert = notificationFacade.buildAlertControlForError(error as NSError)
            notificationFacade.showAlertController(alert)
        }
        if (valid) {
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
}

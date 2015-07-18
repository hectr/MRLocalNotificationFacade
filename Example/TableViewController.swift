
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
        var error: NSError?
        if (repeatSwitch.on) {
            notificationFacade.customizeNotificationRepeat(notification, interval: NSCalendarUnit.CalendarUnitMinute)
        }
        notificationFacade.customizeNotification(notification, appIconBadge: badgeTextField.text.toInt()!, sound: soundSwitch.on)
        var valid = notificationFacade.scheduleNotification(notification, withError: &error)
        if (error != nil) {
            let alert = notificationFacade.buildAlertControlForError(error)
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

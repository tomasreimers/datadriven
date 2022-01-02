//
//  ComplicationController.swift
//  DataDrivenWatch WatchKit Extension
//
//  Created by Tomas Reimers on 12/26/21.
//

import ClockKit


class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Complication Configuration

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let shortcuts = loadFromDisk()

        let descriptors = shortcuts.map {
            shortcut in
            return CLKComplicationDescriptor(identifier: shortcut.id, displayName: shortcut.name, supportedFamilies: [CLKComplicationFamily.utilitarianSmall])
        }
        
        // Call the handler with the currently supported complication descriptors
        handler(descriptors)
    }
    
    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }

    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        handler(CLKComplicationTimelineEntry(date: Date(), complicationTemplate: CLKComplicationTemplateUtilitarianSmallFlat(textProvider: CLKSimpleTextProvider(text: getComplicationValue(id: complication.identifier)))))
    }
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([])
    }
    

    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        handler(CLKComplicationTemplateUtilitarianSmallFlat.init(textProvider: CLKSimpleTextProvider(text: "value")))
    }
}

//
//  HealthKitManager.swift
//  FitTrack
//
//  Created by Nolan Wira on 11/25/24.
//

import HealthKit
import SwiftUI

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private var healthStore = HKHealthStore()
    @Published var isAuthorized = false
    @Published var activeEnergy: Double = 0
    @Published var restingEnergy: Double = 0
    @Published var steps: Int = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    init() {
        if hasCompletedOnboarding {
            checkAuthorizationStatus() // Actively requests authorization if needed
        } else {
            checkInitialAuthorizationStatus() // Only checks current status
        }
    }
    
    var totalCaloriesBurned: Double {
        return activeEnergy + restingEnergy
    }
    
    // Expanded types for reading from HealthKit
    private var healthKitTypes: Set<HKSampleType> {
        guard let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let restingEnergy = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
              let steps = HKObjectType.quantityType(forIdentifier: .stepCount)
        else {
            return []
        }
        
        return [activeEnergy, restingEnergy, steps]
    }
    
    private func checkInitialAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        // Check authorization status for each type
        let authorizationStatus = healthKitTypes.map { type in
            healthStore.authorizationStatus(for: type)
        }
        
        // If all types are authorized, set isAuthorized to true and start observing
        let allAuthorized = authorizationStatus.allSatisfy { $0 == .sharingAuthorized }
        
        DispatchQueue.main.async {
            self.isAuthorized = allAuthorized
            if allAuthorized {
                self.startObservingHealth()
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        Task {
            do {
                try await healthStore.requestAuthorization(toShare: [], read: healthKitTypes)
                DispatchQueue.main.async {
                    self.isAuthorized = true
                    self.startObservingHealth()
                }
            } catch {
                print("Authorization failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isAuthorized = false
                }
            }
        }
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        Task {
            do {
                try await healthStore.requestAuthorization(toShare: [], read: healthKitTypes)
                DispatchQueue.main.async {
                    self.isAuthorized = true
                    self.startObservingHealth()
                }
            } catch {
                print("Authorization failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isAuthorized = false
                }
            }
        }
    }
    
    func disconnect() {
        DispatchQueue.main.async {
            self.isAuthorized = false
            self.activeEnergy = 0
            self.restingEnergy = 0
            self.steps = 0
        }
    }
    
    private func startObservingHealth() {
        print("Starting to observe health metrics...")
        updateActiveEnergy()
        updateRestingEnergy()
        updateSteps()
        setupObservers()
    }
    
    private func setupObservers() {
        guard let activeType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let restingType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
              let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        // Observer for active energy
        let activeObserver = HKObserverQuery(sampleType: activeType, predicate: predicate) { [weak self] _, completion, error in
            if let error = error {
                print("Active energy observer error: \(error.localizedDescription)")
            } else {
                self?.updateActiveEnergy()
            }
            completion()
        }
        
        // Observer for resting energy
        let restingObserver = HKObserverQuery(sampleType: restingType, predicate: predicate) { [weak self] _, completion, error in
            if let error = error {
                print("Resting energy observer error: \(error.localizedDescription)")
            } else {
                self?.updateRestingEnergy()
            }
            completion()
        }
        
        // Observer for steps
        let stepsObserver = HKObserverQuery(sampleType: stepsType, predicate: predicate) { [weak self] _, completion, error in
            if let error = error {
                print("Steps observer error: \(error.localizedDescription)")
            } else {
                self?.updateSteps()
            }
            completion()
        }
        
        healthStore.execute(activeObserver)
        healthStore.execute(restingObserver)
        healthStore.execute(stepsObserver)
        
        // Enable background delivery for all types
        [activeType, restingType, stepsType].forEach { type in
            healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { success, error in
                if let error = error {
                    print("Failed to enable background delivery for \(type.identifier): \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updateSteps() {
        guard let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            print("Failed to create steps type")
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepsType,
                                    quantitySamplePredicate: predicate,
                                    options: .cumulativeSum) { [weak self] _, result, error in
            if let error = error {
                print("Error fetching steps: \(error.localizedDescription)")
                return
            }
            
            guard let result = result, let sum = result.sumQuantity() else {
                print("No steps data available")
                return
            }
            
            DispatchQueue.main.async {
                self?.steps = Int(sum.doubleValue(for: .count()))
                print("Updated steps: \(Int(sum.doubleValue(for: .count())))")
            }
        }
        
        healthStore.execute(query)
    }
    
    private func updateActiveEnergy() {
        guard let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            print("Failed to create active energy type")
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: activeEnergyType,
                                    quantitySamplePredicate: predicate,
                                    options: .cumulativeSum) { [weak self] _, result, error in
            if let error = error {
                print("Error fetching active energy: \(error.localizedDescription)")
                return
            }
            
            guard let result = result, let sum = result.sumQuantity() else {
                print("No active energy data available")
                return
            }
            
            DispatchQueue.main.async {
                self?.activeEnergy = sum.doubleValue(for: .kilocalorie())
                print("Updated active energy: \(sum.doubleValue(for: .kilocalorie())) kcal")
            }
        }
        
        healthStore.execute(query)
    }
    
    private func updateRestingEnergy() {
        guard let restingEnergyType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) else {
            print("Failed to create resting energy type")
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: restingEnergyType,
                                    quantitySamplePredicate: predicate,
                                    options: .cumulativeSum) { [weak self] _, result, error in
            if let error = error {
                print("Error fetching resting energy: \(error.localizedDescription)")
                return
            }
            
            guard let result = result, let sum = result.sumQuantity() else {
                print("No resting energy data available")
                return
            }
            
            DispatchQueue.main.async {
                self?.restingEnergy = sum.doubleValue(for: .kilocalorie())
                print("Updated resting energy: \(sum.doubleValue(for: .kilocalorie())) kcal")
            }
        }
        
        healthStore.execute(query)
    }
}

//
//  ResultOperation.swift
//  MullvadVPN
//
//  Created by pronebird on 23/03/2022.
//  Copyright © 2022 Mullvad VPN AB. All rights reserved.
//

import Foundation

class ResultOperation<Success, Failure: Error>: AsyncOperation {
    typealias Completion = OperationCompletion<Success, Failure>
    typealias CompletionHandler = (Completion) -> Void

    private let stateLock = NSLock()
    private let completionQueue: DispatchQueue?
    private var completionHandler: CompletionHandler?
    private var isPendingFinish = false
    private lazy var queueMarkerKey = DispatchSpecificKey<Bool>()

    init(completionQueue: DispatchQueue?, completionHandler: CompletionHandler?) {
        self.completionQueue = completionQueue
        self.completionHandler = completionHandler

        super.init()

        // Mark completion queue unless it's main queue.
        if let completionQueue = completionQueue, completionQueue != .main {
            completionQueue.setSpecific(key: queueMarkerKey, value: true)
        }
    }

    deinit {
        // Remove marker from queue.
        if let completionQueue = completionQueue, completionQueue != .main {
            completionQueue.setSpecific(key: queueMarkerKey, value: nil)
        }
    }

    override func finish() {
        // Propagate cancellation if finish() is called directly from start().
        if isCancelled {
            finish(completion: .cancelled)
        } else {
            preconditionFailure("Use finish(completion:) to finish operation.")
        }
    }

    func finish(completion: Completion) {
        stateLock.lock()

        // Bail if operation is already finishing.
        guard !isPendingFinish else {
            stateLock.unlock()
            return
        }

        // Mark operation as finishing.
        isPendingFinish = true

        // Acquire completion handler.
        let completionHandler: CompletionHandler? = self.completionHandler

        // Reset completion handler.
        self.completionHandler = nil

        stateLock.unlock()

        let dispatchBlock = {
            // Call completion handler.
            completionHandler?(completion)

            // Finish operation.
            super.finish()
        }

        // Run completion handler immediately if running on completion queue or if it's unset.
        guard let completionQueue = completionQueue,
              (completionQueue == .main && Thread.isMainThread) ||
                DispatchQueue.getSpecific(key: queueMarkerKey) == true
        else {
            dispatchBlock()
            return
        }

        // Otherwise dispatch asynchronously.
        completionQueue.async(execute: dispatchBlock)
    }
}

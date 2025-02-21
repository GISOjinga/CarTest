--!strict
--[[
    This module will run through every test case 
    It will run as long as the workspaces "StartTest" attribute is true
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")


-- modules
local _types = require(ReplicatedStorage.Types)
local testCaseMethods = require(ReplicatedStorage.Methods.TestCaseMethods) -- holds the check functions for each test case
local motorMethods = require(ReplicatedStorage.Methods.MotorMethods)


-- variables
local trackingEvent = Instance.new("BindableEvent")
local testingEnded = Instance.new("BindableEvent")
local module = {
    Changed = trackingEvent.Event,
    Ended = testingEnded.Event,
}



--[[
    * Will start tracking each constraint
    * Will fire events when a change is made to the test case (usually when a test fails)
]]
function module.startTracking(car:_types.Car)
    local startTime = os.clock()
    local constraints = motorMethods:getAllConstraints(car::any)
    local passedTestCases, failedTestCases = {}, {}
    local testCasesCheckList = { -- test cases use this for tracking changes
        SevereTestCases = {},
        SpringConstraint = {},
        AlignPosition = {},
        AngularVelocity = {},
        CylindricalConstraint = {},
        AlignOrientation = {},
    }
    
    --trackingEvent.Event:Connect(print) -- prints changes

    -- checks if a test case has failed then fires event and also returns false if it is a severe test case
    local function checkTestCase(passed:boolean, testCaseName:string)
        if (not passed) and testCasesCheckList[testCaseName] then
            trackingEvent:Fire(testCaseName, passed) -- event used for test case changing
            testCasesCheckList[testCaseName] = nil -- removes test from check list
            failedTestCases[#failedTestCases+1] = testCaseName -- registers test as a failed one

            if testCaseName == "SevereTestCases" then -- if failed test was a sever test case then car will stop
                workspace:SetAttribute("StartTest")
                return false
            end
        end

        return true
    end

    -- loop used to check every test case
    while workspace:GetAttribute("StartTest") do
        local newTime = os.clock()

        for testCaseName, testCaseInfo in pairs(testCasesCheckList) do
            local passed:boolean = testCaseMethods[testCaseName](car, constraints, testCaseInfo, newTime-startTime) -- finds if the test has failed or not

            if not checkTestCase(passed, testCaseName) then
                break
            end
        end

        task.wait()
        startTime = newTime
    end

    if car:GetAttribute("Laps") <= 3 then -- makes sure that even if the test stops that if the laps aren't completed in full that test cases will fail
        checkTestCase(false, "SevereTestCases")
    end

    for name in testCasesCheckList do -- adds all failed test cases to a list
        passedTestCases[#passedTestCases+1] = name
    end
    
    testingEnded:Fire(passedTestCases, failedTestCases) -- fires when test case tracker ends
end




return module
//
//  CIError.cpp
//  LuaBridge
//
//  Created by xie.pingjia
//  Copyright (c) 2015 Baidu. All rights reserved.
//

#include "CIError.h"

CIError::CIError()
{
    error_ = false;
}

CIError::~CIError()
{
    error_ = false;
}

bool CIError::isError()
{
    return error_;
}

void CIError::setError()
{
    error_ = true;
}

void CIError::setFailureReason(std::string failureReason)
{
    failureReason_ = failureReason;
}

void CIError::setSuggestion(std::string suggestion)
{
    suggestion_ = suggestion;
}

std::string CIError::description()
{
    std::string failureReason = "FailureReason: " + failureReason_ + "\n";
    std::string suggestion =    "Suggestion   : " + suggestion_ + "\n";
    std::string description = failureReason + suggestion;
    return description;
}

std::string CIError::failureReason()
{
    return failureReason_;
}

std::string CIError::suggestion()
{
    return suggestion_;
}
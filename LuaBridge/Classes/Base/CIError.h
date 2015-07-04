//
//  CIError.h
//  LuaBridge
//
//  Created by xie.pingjia
//  Copyright (c) 2015 Baidu. All rights reserved.
//

#ifndef __CICore__CIError__
#define __CICore__CIError__

#include <stdio.h>
#include <string>

class CIError {
public:
    CIError();
    ~CIError();
    
    bool isError();
    
    void setFailureReason(std::string failureReason);
    void setSuggestion(std::string suggestion);
    void setError();
    
    std::string description();
    std::string failureReason();
    std::string suggestion();
    
private:
    std::string failureReason_;
    std::string suggestion_;
    bool error_;
};
#endif /* defined(__CICore__CIError__) */

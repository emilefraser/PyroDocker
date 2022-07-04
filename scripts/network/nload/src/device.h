/*
 * nload
 * real time monitor for network traffic
 * Copyright (C) 2001 - 2018 by Roland Riegel <feedback@roland-riegel.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#ifndef DEVICE_H
#define DEVICE_H

#include "dataframe.h"
#include "statistics.h"

#include <string>

class DevReader;
class Window;

class Device
{
    public:
        explicit Device(DevReader* devReader);
        ~Device();

        bool exists() const;

        const std::string& getName() const;
        const std::string& getIpV4Address() const;

        const Statistics& getStatistics() const;

        void update();
        
    private:
        void fixOverflows(DataFrame& dataFrame, const DataFrame& dataFrameOld);
        unsigned long long fixOverflow(unsigned long long value, unsigned long long valueOld);

        DevReader* m_devReader;

        std::string m_name;
        std::string m_ipv4;

        Statistics m_deviceStatistics;
        DataFrame m_dataFrameOld;
};

#endif


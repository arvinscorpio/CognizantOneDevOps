#! /bin/sh
# /etc/init.d/InSightsConcourseAgent

### BEGIN INIT INFO
# Provides: Runs a Python script on startup
# Required-Start: BootPython start
# Required-Stop: BootPython stop
# Default-Start: 2 3 4 5
# Default-stop: 0 1 6
# Short-Description: Simple script to run python program at boot
# Description: Runs a python program at boot
### END INIT INFO
#export INSIGHTS_AGENT_HOME=/home/ec2-user/insightsagents
source /etc/profile

case "$1" in
  start)
    if [[ $(ps aux | grep '[c]i.concourse.ConcourseAgent' | awk '{print $2}') ]]; then
     echo "InSightsConcourseAgent already running"
    else
     echo "Starting InSightsConcourseAgent"
     cd $INSIGHTS_AGENT_HOME/PlatformAgents/concourse
     python -c "from com.cognizant.devops.platformagents.agents.ci.concourse.ConcourseAgent import ConcourseAgent; ConcourseAgent()" &
    fi
    if [[ $(ps aux | grep '[c]i.concourse.ConcourseAgent' | awk '{print $2}') ]]; then
     echo "InSightsConcourseAgent Started Sucessfully"
    else
     echo "InSightsConcourseAgent Failed to Start"
    fi
    ;;
  stop)
    echo "Stopping InSightsConcourseAgent"
    if [[ $(ps aux | grep '[c]i.concourse.ConcourseAgent' | awk '{print $2}') ]]; then
     sudo kill -9 $(ps aux | grep '[c]i.concourse.ConcourseAgent' | awk '{print $2}')
    else
     echo "InSightsConcourseAgent already in stopped state"
    fi
    if [[ $(ps aux | grep '[c]i.concourse.ConcourseAgent' | awk '{print $2}') ]]; then
     echo "InSightsConcourseAgent Failed to Stop"
    else
     echo "InSightsConcourseAgent Stopped"
    fi
    ;;
  restart)
    echo "Restarting InSightsConcourseAgent"
    if [[ $(ps aux | grep '[c]i.concourse.ConcourseAgent' | awk '{print $2}') ]]; then
     echo "InSightsConcourseAgent stopping"
     sudo kill -9 $(ps aux | grep '[c]i.concourse.ConcourseAgent' | awk '{print $2}')
     echo "InSightsConcourseAgent stopped"
     echo "InSightsConcourseAgent starting"
     cd $INSIGHTS_AGENT_HOME/PlatformAgents/concourse
     python -c "from com.cognizant.devops.platformagents.agents.ci.concourse.ConcourseAgent import ConcourseAgent; ConcourseAgent()" &
     echo "InSightsConcourseAgent started"
    else
     echo "InSightsConcourseAgent already in stopped state"
     echo "InSightsConcourseAgent starting"
     cd $INSIGHTS_AGENT_HOME/PlatformAgents/concourse
     python -c "from com.cognizant.devops.platformagents.agents.ci.concourse.ConcourseAgent import ConcourseAgent; ConcourseAgent()" &
     echo "InSightsConcourseAgent started"
    fi
    ;;
  status)
    echo "Checking the Status of InSightsConcourseAgent"
    if [[ $(ps aux | grep '[c]i.concourse.ConcourseAgent' | awk '{print $2}') ]]; then
     echo "InSightsConcourseAgent is running"
    else
     echo "InSightsConcourseAgent is stopped"
    fi
    ;;
  *)
    echo "Usage: /etc/init.d/InSightsConcourseAgent {start|stop|restart|status}"
    exit 1
    ;;
esac
exit 0
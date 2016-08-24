# FogBubble

FogBubble is a
[Curses-based](https://en.wikipedia.org/wiki/Curses_%28programming_library%29#Curses-based_software)
dashboard for your [FogBugz](http://www.fogcreek.com/fogbugz/) projects and
tasks. FogBugz has a
[feature](http://help.fogcreek.com/7681/fogbugz-working-schedules#_Time_Spent_per_Project)
which allows you to allocate portions of your working time, sometimes called
protected time, towards each of specific projects. FogBubble helps you stay
on target with these allocations (or revise them to better reflect your working
reality).

The dashboard has three panes. The left-hand side shows a selection
of tasks you've resolved in each of the past several days to help you see at a
glance your progress — or that you need to kick it into gear. The bottom
lists the task you're currently logging time against in FogBugz.

The right-hand side pane shows a selection of active tasks you might choose
to work on next for each of several projects. The projects are listed in
descending order of how much attention they require for you to stay on target
with your time allocations, so that as a protected project falls into neglect
it bubbles up the pane. The number of tasks shown under each project
heading is a logarithmic function of the time required to be logged
against a project's tasks to bring it current.

Many FogBugz users seem to successfully look in regularly enough on each of
their projects, but I can't seem to avoid lapses in keeping the system up to
date. I hope this dashboard will help me trustily get to each of my projects in
turn without worrying about any falling through the cracks.

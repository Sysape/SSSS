Um well I suppose I should write a readme as this is going to be tagged as 
a release.

This is a web-engined system for mantaining a database of contacts for 
Solstice Energy a solar power engineering firm based in London. 
see http://www.solsticeenergy.co.uk for more on them.

It uses perl's Template toolkit to produce a webform that submits updates
to customer records in a mysql database.

There's a bunch of javascript to add to the usability of the form. Well
jquery really. So far I'm using thier ui library, a dirtyFields plugin
 jqEasyCharCounter, although a modified version. fileuploader.js from
vallums, and supertextarea, although I haven't got that working yet.

-- NTS add urls to this doc for the above --

So far it's a hand crafted web application system, I'm debating putting it
into some kind of framework, like CGI::Application 

The next few steps will involve adding in a suppliers table and a project
management table so we can record what gear's been ordered for a job.

Then adding a quote engine using Latex templates to produce pdf output

and finally a design tool to help with finding the best combination of 
PV modules and/or Hot water systems for a roof.

All the code I wrote is 
Copyright Michael J G Day, 2010 
contact via code[at]gatrell[dot]org 

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

I hope I've remembered to leave attributions and licenses intact for
code other people wrote, I hope to get the round tuits to check some
day.

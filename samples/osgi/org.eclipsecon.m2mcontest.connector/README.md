Use this bundle to quickly connect your OSGi application to the EclipseCon Europe M2M server!

* The bundle exposes an IM2MServerAccessor service which does most of the HTTP/REST/JSON stuff for you, and allows you to manipulate query results in your Java code.
* A OSGi Event is posted as soon a new value is available for a sensor. The event topic is m2m/sensor/SENSOR_NAME, the event message is the value, and its timestamp is the time at which the data was acquired
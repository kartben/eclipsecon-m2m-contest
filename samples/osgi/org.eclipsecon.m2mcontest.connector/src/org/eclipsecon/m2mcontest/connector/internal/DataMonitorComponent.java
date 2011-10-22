/*******************************************************************************
 * Copyright (c) 2011 Sierra Wireless All rights reserved. This program and the
 * accompanying materials are made available under the terms of the Eclipse
 * Public License v1.0 which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors: Benjamin Cabé (Sierra Wireless) - initial API and
 * implementation
 *******************************************************************************/
package org.eclipsecon.m2mcontest.connector.internal;

import java.util.Date;
import java.util.Dictionary;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.Timer;
import java.util.TimerTask;

import org.eclipsecon.m2mcontest.connector.IM2MServerAccessor;
import org.eclipsecon.m2mcontest.connector.M2MContestConstants;
import org.eclipsecon.m2mcontest.connector.resources.data.Data;
import org.eclipsecon.m2mcontest.connector.resources.info.Info;
import org.eclipsecon.m2mcontest.connector.resources.info.SensorInfo;
import org.osgi.service.component.ComponentContext;
import org.osgi.service.event.Event;
import org.osgi.service.event.EventAdmin;
import org.osgi.service.event.EventConstants;

/**
 * Monitor the arrival of new data on the M2M server.<br>
 * Post an {@link Event} with the following format:
 * <code>m2m/sensor/SENSOR_ID</code> when it happens.<br>
 * The following event properties are set:
 * <ul>
 * <li> {@link EventConstants#MESSAGE}: the value</li>
 * <li>{@link EventConstants#TIMESTAMP}: the timestamp of the value</li>
 * </ul>
 */
public class DataMonitorComponent {
	// sensorId --> lastValueTimestamp
	private Map<String, Date> _monitoredValues = new HashMap<String, Date>();
	private IM2MServerAccessor _serverAccessor;
	private EventAdmin _eventAdmin;

	protected void activate(ComponentContext cctx) {
		Integer pollingInterval = (Integer) cctx.getProperties().get(
				"pollingInterval");
		if (pollingInterval == null)
			pollingInterval = 10;
		// retrieve the list of sensors declared on the server
		Info info = _serverAccessor.getSensorInfo(null, null, 50);
		for (SensorInfo i : info.results) {
			_monitoredValues.put(i.sensor, null);

			Timer timer = new Timer();
			timer.schedule(new DataMonitor(i.sensor), 0, pollingInterval * 1000);
		}
	}

	private class DataMonitor extends TimerTask {
		private String _sensor;

		/**
		 * @param sensor
		 *            the id of the sensor to monitor
		 */
		public DataMonitor(String sensor) {
			_sensor = sensor;
		}

		@SuppressWarnings("unchecked")
		@Override
		public void run() {
			Data data = _serverAccessor.getSensorData("{\"sensor\":\""
					+ _sensor + "\"}", "{\"_id\":-1}", 1);

			Date newestDate = data.results.get(0).getAcquisitionDate();
			Float newestValue = data.results.get(0).value;

			Date previousDate = _monitoredValues.get(_sensor);
			if (previousDate == null || newestDate.after(previousDate)) {
				_monitoredValues.put(_sensor, newestDate);
				if (_eventAdmin != null) {
					@SuppressWarnings("rawtypes")
					Dictionary p = new Properties();
					p.put(EventConstants.MESSAGE, newestValue);
					p.put(EventConstants.TIMESTAMP, newestDate.getTime());
					_eventAdmin.postEvent(new Event(
							M2MContestConstants.BASE_TOPIC + _sensor, p));
				}
			}
		}
	}

	protected void setServerAccessor(IM2MServerAccessor serverAccessor) {
		_serverAccessor = serverAccessor;
	}

	protected void setEventAdmin(EventAdmin eventAdmin) {
		_eventAdmin = eventAdmin;
	}
}

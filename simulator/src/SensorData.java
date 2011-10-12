/*******************************************************************************
 * Copyright (c) 2011 Sierra Wireless All rights reserved. This program and the
 * accompanying materials are made available under the terms of the Eclipse
 * Public License v1.0 which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors: Benjamin Cabé (Sierra Wireless) - initial API and
 * implementation
 *******************************************************************************/
import com.mongodb.BasicDBObject;

@SuppressWarnings("serial")
public class SensorData extends BasicDBObject {
	private static final String SENSOR_NAME_KEY = "sensor";
	private static final String SENSOR_VALUE_KEY = "value";

	public SensorData(String name, Number value) {
		this.put(SENSOR_NAME_KEY, name);
		this.put(SENSOR_VALUE_KEY, value);
	}

	@Override
	public String toString() {
		return "SensorData: \"" + this.get(SENSOR_NAME_KEY) + "\" "
				+ this.get(SENSOR_VALUE_KEY);
	}
}

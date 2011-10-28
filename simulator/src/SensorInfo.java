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
public class SensorInfo extends BasicDBObject {
	private static final String SENSOR_NAME_KEY = "sensor";
	private static final String SENSOR_TYPE_KEY = "type";
	private static final String SENSOR_DESCRIPTION_KEY = "description";
	private static final String SENSOR_UNIT_KEY = "unit";

	public SensorInfo(String name, String type, String desc, String unit) {
		this.put(SENSOR_NAME_KEY, name);
		this.put(SENSOR_TYPE_KEY, type);
		this.put(SENSOR_DESCRIPTION_KEY, desc);
		this.put(SENSOR_UNIT_KEY, unit);
	}

	@Override
	public String toString() {
		return "SensorInfo: \"" + this.get(SENSOR_NAME_KEY) + "\" "
				+ this.get(SENSOR_TYPE_KEY) + "\" "
				+ this.get(SENSOR_DESCRIPTION_KEY) + "\" "
				+ this.get(SENSOR_UNIT_KEY);
	}

}

/*******************************************************************************
 * Copyright (c) 2011 Sierra Wireless All rights reserved. This program and the
 * accompanying materials are made available under the terms of the Eclipse
 * Public License v1.0 which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors: Benjamin Cabé (Sierra Wireless) - initial API and
 * implementation
 *******************************************************************************/
import java.net.UnknownHostException;
import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;

import com.mongodb.DB;
import com.mongodb.DBCollection;
import com.mongodb.Mongo;
import com.mongodb.MongoException;

public class Main {

	private final static Map<String, SimulationParameter> simulatedSensors = new HashMap<String, SimulationParameter>();

	static {
		simulatedSensors.put("CUBE_TEMPERATURE", new SimulationParameter(1900,
				2600, 50));
		simulatedSensors.put("CUBE_ILLUMINANCE", new SimulationParameter(200,
				15000, 50));

		simulatedSensors.put("STATION1_TEMPERATURE", new SimulationParameter(
				1900, 2600, 25));
		simulatedSensors.put("STATION1_ILLUMINANCE", new SimulationParameter(
				200, 15000, 20));

		simulatedSensors.put("STATION2_TEMPERATURE", new SimulationParameter(
				1900, 2600, 25));
		simulatedSensors.put("STATION2_ILLUMINANCE", new SimulationParameter(
				200, 15000, 80));

	}

	public static void main(String[] args) {
		System.out.println("Starting simulation");
		Mongo m;
		try {
			m = new Mongo("91.121.117.128", 27017);
			DB db = m.getDB("sensors");
			DBCollection c = db.getCollection("data");

			while (true) {
				for (Entry<String, SimulationParameter> entry : simulatedSensors
						.entrySet()) {
					String sensorName = entry.getKey();
					SimulationParameter simulationParameter = entry.getValue();

					SensorData sensorData = null;
					if (sensorName.endsWith("TEMPERATURE")) {
						sensorData = new SensorData(sensorName,
								simulationParameter.updateValue() / 100.0);
					} else {
						sensorData = new SensorData(sensorName,
								simulationParameter.updateValue());
					}
					System.out.println(sensorData);
					c.insert(sensorData);
				}
				Thread.sleep(50);
			}
		} catch (UnknownHostException e) {
			e.printStackTrace();
		} catch (MongoException e) {
			e.printStackTrace();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}
}

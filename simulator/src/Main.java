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
import java.util.Timer;
import java.util.TimerTask;

import com.mongodb.DB;
import com.mongodb.DBCollection;
import com.mongodb.MapReduceCommand;
import com.mongodb.MapReduceCommand.OutputType;
import com.mongodb.Mongo;
import com.mongodb.MongoException;

public class Main {

	private final static Map<String, SimulationParameter> simulatedSensors = new HashMap<String, SimulationParameter>();

	static {
		simulatedSensors.put("CUBE_TEMPERATURE", new SimulationParameter(1900,
				2600, 10));
		simulatedSensors.put("CUBE_ILLUMINANCE", new SimulationParameter(200,
				15000, 50));

		simulatedSensors.put("STATION1_TEMPERATURE", new SimulationParameter(
				1900, 2600, 10));
		simulatedSensors.put("STATION1_ILLUMINANCE", new SimulationParameter(
				200, 15000, 20));

		simulatedSensors.put("STATION2_TEMPERATURE", new SimulationParameter(
				1900, 2600, 10));
		simulatedSensors.put("STATION2_ILLUMINANCE", new SimulationParameter(
				200, 15000, 80));
	}

	private static Map<String, Integer> consolidationJobs = new HashMap<String, Integer>();
	static {
		consolidationJobs.put("consolidatedData_OneMinute", 60 * 1000);
		consolidationJobs.put("consolidatedData_FiveMinute", 5 * 60 * 1000);
		consolidationJobs.put("consolidatedData_OneHour", 60 * 60 * 1000);
	}

	public static void main(String[] args) {
		System.out.println("Starting simulation");

		Mongo m;
		try {
			m = new Mongo("91.121.117.128", 27017);
			DB db = m.getDB("sensors");
			final DBCollection sensorsCollection = db.getCollection("data");

			// schedule data consolidation jobs
			int delay = 0;
			for (final Entry<String, Integer> entry : consolidationJobs
					.entrySet()) {

				Timer t = new Timer(entry.getKey() + " consolidation job");

				t.schedule(new TimerTask() {
					@Override
					public void run() {
						performMapReduce(sensorsCollection, entry.getKey(),
								entry.getValue());
					}
				}, (5 * delay++ * 1000), 20 * 1000);

			}

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
					sensorsCollection.insert(sensorData);
				}
				Thread.sleep(5000);
			}
		} catch (UnknownHostException e) {
			e.printStackTrace();
		} catch (MongoException e) {
			e.printStackTrace();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}

	private static void performMapReduce(DBCollection collection,
			String outputCollection, int interval) {
		System.out
				.println("Consolidating data for " + outputCollection + "...");

		String map = "function() {\r\n"
				+ "            emit( {sensorId: this.sensor, ts: new Date(parseInt( (this._id.getTimestamp()/ INTERVAL) + \"\" ) * INTERVAL)} , { sensorId: this.sensor, total: this.value, min: this.value, max: this.value, count: 1  } );\r\n"
				+ "};";

		String reduce = "function( key , values ){\r\n"
				+ "    var total = 0;\r\n"
				+ "    var min = 0;\r\n"
				+ "    var max = 0;\r\n"
				+ "    for ( var i=0; i<values.length; i++ ) {\r\n"
				+ "        var v = values[i].total;\r\n"
				+ "        if (i == 0) {\r\n"
				+ "            min = v ;\r\n"
				+ "            max = v ;\r\n"
				+ "        }\r\n"
				+ "        total += v;\r\n"
				+ "        min = Math.min(v, min);\r\n"
				+ "        max = Math.max(v, max);\r\n"
				+ "    }\r\n"
				+ "    return { sensorId: key.sensorId, total: total, min: min, max: max, count: values.length };\r\n"
				+ "};";

		String finalize = "function ( who , res ){\r\n"
				+ "    avg = res.total / res.count;\r\n"
				+ "    return {sensorId: res.sensorId, nbSamples: res.count, average: avg, minimum: res.min, maximum: res.max};\r\n"
				+ "}";

		MapReduceCommand mrc = new MapReduceCommand(collection, map, reduce,
				outputCollection, OutputType.REPLACE, null);

		mrc.setFinalize(finalize);

		Map<String, Object> scope = new HashMap<String, Object>();
		scope.put("INTERVAL", interval);
		mrc.setScope(scope);

		collection.mapReduce(mrc);

		System.out.println("... data consolidation for " + outputCollection
				+ "... done!");

	}
}

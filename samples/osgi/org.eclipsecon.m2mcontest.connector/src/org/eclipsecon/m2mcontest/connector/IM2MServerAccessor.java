/*******************************************************************************
 * Copyright (c) 2011 Sierra Wireless All rights reserved. This program and the
 * accompanying materials are made available under the terms of the Eclipse
 * Public License v1.0 which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors: Benjamin Cabé (Sierra Wireless) - initial API and
 * implementation
 *******************************************************************************/
package org.eclipsecon.m2mcontest.connector;

import org.eclipsecon.m2mcontest.connector.resources.consolidatedData.ConsolidatedData;
import org.eclipsecon.m2mcontest.connector.resources.data.Data;
import org.eclipsecon.m2mcontest.connector.resources.info.Info;

public interface IM2MServerAccessor {
	public abstract Data getSensorData(String criteria, String sort);

	public abstract Data getSensorData(String criteria, String sort,
			int maxResults);

	public abstract ConsolidatedData getSensorConsolidatedData(
			CONSOLIDATION_RANGE range, String criteria, String sort);

	public abstract ConsolidatedData getSensorConsolidatedData(
			CONSOLIDATION_RANGE range, String criteria, String sort,
			int maxResults);

	public abstract Info getSensorInfo(String criteria, String sort);

	public abstract Info getSensorInfo(String criteria, String sort,
			int maxResults);

}
/******************************************************************************
 * Error response for any message *********************************************
 ******************************************************************************/
export interface ErrorResponse {
  error: string;
}
/******************************************************************************
 * Ping ***********************************************************************
 ******************************************************************************/
export interface PingMessage {
  type: typeof MessagesToBackgroundPage.Ping;
}
export interface PingResponse {
  type: string;
  details: {
    version: string;
    manifestVersion: number;
    name: string;
    extensionId: string;
    platform: string;
    userAgent: string;
  };
}
